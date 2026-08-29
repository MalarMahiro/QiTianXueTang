import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api.dart';
import 'logger.dart';
import 'qitian_crypto.dart';
import 'secure_crypto.dart';

/// 封装Dio HTTP客户端
/// Ponytail: 依据真实抓包。认证用 Token + Version 头(非Bearer)。响应若 isEncrypt 则AES解密。
/// token 用内存缓存 + secure storage 双写，secure storage 失败不阻断登录。
class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  String? _memToken; // 内存token缓存，secure storage不可用时保证会话可用

  DioClient._internal();
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  Dio get dio => _dio;

  void init() {
    _dio = Dio(BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Accept-Charset': 'UTF-8',
        'Version': ApiConfig.version,
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome Mobile Safari/537.36',
        'Accept-Encoding': 'gzip',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 认证头 Token(非Bearer)。优先内存缓存，其次secure storage。
        var token = _memToken;
        if (token == null) {
          try {
            token = await _storage.read(key: _tokenKey);
            _memToken = token;
          } catch (_) {}
        }
        if (token != null && token.isNotEmpty) {
          options.headers['Token'] = token;
        }
        // 若已协商会话AES key，附带 bk 头（供带bn的isEncrypt接口使用）
        if (SecureCrypto.hasKey) {
          options.headers['bk'] = SecureCrypto.buildBk();
        }
        logger.debug('HTTP', '→ ${options.method} ${options.baseUrl}${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) async {
        logger.debug('HTTP', '← ${response.statusCode} ${response.requestOptions.path}');
        // 统一兜底：JSON 响应体可能以原始 String 形式返回(响应没带 application/json content-type，
        // 导致 Dio 不做自动解析)。根因修复——所有下游都依赖 body 是 Map/List。
        if (response.data is String) {
          final s = response.data as String;
          try {
            final decoded = jsonDecode(s);
            if (decoded is Map || decoded is List) response.data = decoded;
          } catch (_) {}
        }
        // 解密响应体: data.isEncrypt==true → AES解密 content
        try {
          final data = response.data;
          if (data is Map && data['data'] is Map) {
            final inner = data['data'] as Map;
            if (inner['isEncrypt'] == true && inner['content'] != null) {
              final content = inner['content'].toString();
              String decrypted;
              if (inner['bn'] != null) {
                // 带 bn(iv) → 会话AES key + GCM
                decrypted = SecureCrypto.aesGcmDecrypt(content, inner['bn'].toString());
              } else {
                // 无 bn → 固定 AES key + ECB
                decrypted = QitianCrypto.aesEcbDecryptBase64(content);
              }
              inner['content'] = decrypted;
              try {
                inner['decryptedData'] =
                    (jsonDecode(decrypted) as Map).cast<String, dynamic>();
              } catch (_) {}
            }
          }
        } catch (e) {
          logger.warn('HTTP', '响应解密失败: $e');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        logger.warn(
            'HTTP', '✗ ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// 登录(表单)并保存token
  Future<String?> login(String userCode, String password) async {
    final resp = await _dio.post(
      '${ApiConfig.baseUser}${ApiConfig.login}',
      data: {'userCode': userCode, 'password': QitianCrypto.encryptPassword(password)},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final body = resp.data;
    logger.debug('HTTP', '← login body: ${body.toString()}  type=${body.runtimeType}');
    // 兼容 String(原始JSON) 与 Map(已解析) 两种响应体
    Map<String, dynamic>? parsed;
    if (body is Map) {
      parsed = Map<String, dynamic>.from(body);
    } else if (body is String) {
      try {
        parsed = (jsonDecode(body) as Map).cast<String, dynamic>();
      } catch (_) {}
    }
    if (parsed != null && parsed['status'] == 200 && parsed['data'] != null) {
      final d = parsed['data'] as Map;
      final token = d['token']?.toString();
      if (token != null && token.isNotEmpty) {
        // token 已成功获取，登录即成功。持久化失败不阻断登录（有内存 + AuthProvider 持有）。
        try {
          await saveToken(token);
        } catch (e) {
          logger.warn('HTTP', '登录token持久化失败(忽略): $e');
        }
        logger.debug('HTTP', '← login token 提取成功: ${token.substring(0, 10)}...');
        // 登录成功后协商会话AES key（用于带bn的isEncrypt接口，如GetUserInfo）
        try {
          await negotiateKey();
        } catch (e) {
          logger.warn('HTTP', '会话密钥协商失败(忽略): $e');
        }
        return token;
      }
      logger.warn('HTTP', '← login data.token 为空: data=$d');
    } else {
      logger.warn('HTTP', '← login 响应结构异常: body=$body type=${body.runtimeType}');
    }
    return null;
  }

  bool _isNegotiating = false;
  Completer<void>? _negotiationCompleter;

  /// 确保会话级 AES key 有效（冷启动后重新协商）
  Future<void> _ensureSessionKey() async {
    if (SecureCrypto.hasKey) return;
    if (_isNegotiating) {
      // 等待正在进行的协商完成
      await _negotiationCompleter?.future;
      return;
    }
    _isNegotiating = true;
    _negotiationCompleter = Completer<void>();
    try {
      await negotiateKey();
      _negotiationCompleter?.complete();
    } catch (e) {
      _negotiationCompleter?.completeError(e);
      rethrow;
    } finally {
      _isNegotiating = false;
    }
  }

  /// 协商会话级 AES key（原App: POST szone-my/user，空body，head bk）。
  /// 成功后 SecureCrypto 持有该 key，后续带bn的isEncrypt接口用其GCM解密。
  Future<void> negotiateKey() async {
    // 生成新的随机会话AES key
    SecureCrypto.generateSessionKey();
    final bk = SecureCrypto.buildBk();
    logger.debug('HTTP', '→ 协商会话密钥 bk=${bk.substring(0, 12)}...');
    final resp = await _dio.post(
      '${ApiConfig.baseUser}/user',
      data: <String, dynamic>{},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'bk': bk},
      ),
    );
    final body = resp.data;
    logger.debug('HTTP', '← 会话密钥协商响应: ${body?.toString()} type=${body.runtimeType}');
  }

  /// 获取用户信息(响应AES加密, 解密后存 raw 字符串)
  Future<Map<String, dynamic>?> getUserInfoRaw() async {
    try {
      final resp = await _dio.get('${ApiConfig.baseUser}${ApiConfig.userInfo}');
      final body = resp.data;
      if (body is Map && body['status'] == 200 && body['data'] is Map) {
        final data = body['data'] as Map;
        Map<String, dynamic>? result;
        // 若已解密且有 decryptedData 直接用
        if (data['decryptedData'] is Map) {
          result = (data['decryptedData'] as Map).cast<String, dynamic>();
        } else {
          // 否则解析 content
          final content = data['content']?.toString();
          if (content != null && content.isNotEmpty) {
            final decoded = jsonDecode(content);
            result = (decoded as Map).cast<String, dynamic>();
          }
        }
        if (result != null) {
          logger.debug('HTTP', '← GetUserInfo 字段: ${result.keys.toList()}');
        }
        return result;
      }
      return null;
    } catch (e) {
      logger.error('HTTP', '获取用户信息失败', e);
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    _memToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    if (_memToken != null) return _memToken;
    String? token;
    try {
      token = await _storage.read(key: _tokenKey);
      _memToken = token;
    } catch (_) {}
    return token;
  }

  Future<void> clearToken() async {
    _memToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  // ===== 业务接口 =====
  // 统一取响应 data 对象：解密(AES-ECB待bn/无bn)后返回 data 主体(Map/List)
  dynamic _dataOf(dynamic body) {
    // 如果是 Map 且有 data 字段
    if (body is Map && body['data'] != null) {
      final data = body['data'];
      if (data is Map) {
        // data.isEncrypt==true → interceptor 已写 decryptedData
        if (data['decryptedData'] != null) return data['decryptedData'];
        // data.content 是 AES-ECB 密文但无 bn → 手动解密(兼容无解密兜底)
        if (data['content'] != null && data['isEncrypt'] == true) {
          final decrypted = QitianCrypto.aesEcbDecryptBase64(data['content'].toString());
          try {
            return (jsonDecode(decrypted) as Map).cast<String, dynamic>();
          } catch (_) {
            return decrypted;
          }
        }
        return data;
      }
      return data;
    }
    // ScoreReport 等接口直接返回 data 对象（没有外层 status）
    if (body is Map && body['isEncrypt'] != null) {
      if (body['decryptedData'] != null) return body['decryptedData'];
      if (body['content'] != null && body['isEncrypt'] == true) {
        final decrypted = QitianCrypto.aesEcbDecryptBase64(body['content'].toString());
        try {
          return (jsonDecode(decrypted) as Map).cast<String, dynamic>();
        } catch (_) {
          return decrypted;
        }
      }
      return body;
    }
    return body;
  }

  /// 考试列表 (AES-ECB): GET getClaimExams
  Future<Map<String, dynamic>?> getClaimExams({
    int startIndex = 0, int rows = 20,
    required String schoolGuid, required String grade,
  }) async {
    try {
      final resp = await _dio.get('${ApiConfig.baseScore}${ApiConfig.examGetClaimExams}', queryParameters: {
        'startIndex': startIndex, 'rows': rows, 'schoolGuid': schoolGuid, 'grade': grade,
      });
      final d = _dataOf(resp.data);
      return d is Map ? d.cast<String, dynamic>() : null;
    } catch (e) {
      logger.error('HTTP', 'getClaimExams 失败', e);
      return null;
    }
  }

  /// 未认领考试数 (AES-ECB): GET getExamCount
  Future<Map<String, dynamic>?> getExamCount({
    required String studentName, required String schoolGuid, required String grade,
  }) async {
    try {
      final resp = await _dio.get('${ApiConfig.baseScore}${ApiConfig.examGetExamCount}', queryParameters: {
        'studentName': studentName, 'schoolGuid': schoolGuid, 'grade': grade,
      });
      final d = _dataOf(resp.data);
      return d is Map ? d.cast<String, dynamic>() : null;
    } catch (e) {
      logger.error('HTTP', 'getExamCount 失败', e);
      return null;
    }
  }

  /// 首页宫格导航: GET UNavigation/list (明文)
  Future<List<String>?> getNavigation({
    required String grade, required String schoolGuid,
    required String ruCode, required String cityCode, required String currentGrade,
  }) async {
    try {
      final resp = await _dio.get('${ApiConfig.baseIndex}${ApiConfig.navigationList}', queryParameters: {
        'grade': grade, 'schoolGuid': schoolGuid, 'ruCode': ruCode,
        'cityCode': cityCode, 'currentGrade': currentGrade,
      });
      final d = _dataOf(resp.data);
      if (d is Map) {
        final navs = d['navigations'];
        if (navs is List) return navs.map((e) => e.toString()).toList();
      }
      return null;
    } catch (e) {
      logger.error('HTTP', 'getNavigation 失败', e);
      return null;
    }
  }

  /// 首页板块: GET UPlate/plates (明文)
  Future<List<dynamic>?> getPlates({required String grade, required String currentGrade}) async {
    try {
      final resp = await _dio.get('${ApiConfig.baseIndex}${ApiConfig.plateList}', queryParameters: {
        'grade': grade, 'currentGrade': currentGrade,
      });
      final d = _dataOf(resp.data);
      return d is Map ? (d['list'] as List?)?.toList() : null;
    } catch (e) {
      logger.error('HTTP', 'getPlates 失败', e);
      return null;
    }
  }

  /// 首页广告: GET uad/getAdInfo (明文)
  Future<List<dynamic>?> getAdInfo({
    required String positionCode, required String cityCode, required String ruCode,
    required String grade, required String schoolGuid, required String currentGrade,
  }) async {
    try {
      final resp = await _dio.get('${ApiConfig.baseIndex}${ApiConfig.getAdInfo}', queryParameters: {
        'positionCode': positionCode, 'cityCode': cityCode, 'ruCode': ruCode,
        'grade': grade, 'schoolGuid': schoolGuid, 'currentGrade': currentGrade,
      });
      final d = _dataOf(resp.data);
      return d is Map ? (d['list'] as List?)?.toList() : null;
    } catch (e) {
      logger.error('HTTP', 'getAdInfo 失败', e);
      return null;
    }
  }

  /// 学情数据: GET userInfo/statisticalRefresh (明文)
  Future<Map<String, dynamic>?> getStatistical() async {
    try {
      final resp = await _dio.get('${ApiConfig.baseUser}${ApiConfig.userInfoStatistical}');
      final d = _dataOf(resp.data);
      return d is Map ? d.cast<String, dynamic>() : null;
    } catch (e) {
      logger.error('HTTP', 'getStatistical 失败', e);
      return null;
    }
  }

  /// 消息Top: POST Message/Top (明文)
  Future<Map<String, dynamic>?> getMessageTop() async {
    try {
      final resp = await _dio.post('${ApiConfig.baseUser}${ApiConfig.messageTop}',
          options: Options(contentType: Headers.formUrlEncodedContentType));
      final d = _dataOf(resp.data);
      return d is Map ? d.cast<String, dynamic>() : null;
    } catch (e) {
      logger.error('HTTP', 'getMessageTop 失败', e);
      return null;
    }
  }

  /// 编辑昵称: POST UserInfo/UpdateUserInfo (form nickName)
  Future<Map<String, dynamic>?> updateNickname(String nickName) async {
    try {
      final resp = await _dio.post('${ApiConfig.baseUser}${ApiConfig.userInfoUpdate}',
          data: {'nickName': nickName},
          options: Options(contentType: Headers.formUrlEncodedContentType));
      final d = _dataOf(resp.data);
      return d is Map ? d.cast<String, dynamic>() : null;
    } catch (e) {
      logger.error('HTTP', 'updateNickname 失败', e);
      return null;
    }
  }

  /// 成绩详情 (请求侧GCM加密): POST Question/ScoreReport
  /// 响应 GCM 加密，由拦截器自动解密。bn=iv, bp=加密请求参数, bk已由拦截器自动添加。
  Future<Map<String, dynamic>?> getScoreReport({
    required String examGuid,
    required String schoolGuid,
    required String grade,
  }) async {
    try {
      // 冷启动后会话密钥可能丢失，确保有效
      await _ensureSessionKey();
      
      final iv = SecureCrypto.generateIv();
      final ivBytes = base64.decode(iv);
      final params = jsonEncode({
        'examGuid': examGuid,
        'schoolGuid': schoolGuid,
        'grade': grade,
      });
      logger.debug('HTTP', 'ScoreReport bp 明文: $params');
      final bp = SecureCrypto.aesGcmEncrypt(params, ivBytes);
      final resp = await _dio.post(
        '${ApiConfig.baseScore}${ApiConfig.questionScoreReport}',
        options: Options(headers: {
          'bn': iv,
          'bp': bp,
        }),
      );
      final d = _dataOf(resp.data);
      logger.debug('HTTP', 'ScoreReport 原始响应: ${resp.data}');
      logger.debug('HTTP', 'ScoreReport 解析后: $d');
      if (d is Map) {
        logger.debug('HTTP', 'ScoreReport 解密字段: ${d.keys.toList()}');
      }
      return d is Map ? d.cast<String, dynamic>() : null;
    } catch (e) {
      logger.error('HTTP', 'getScoreReport 失败', e);
      return null;
    }
  }

  /// 获取单科列表 (请求侧GCM加密): POST Question/Subjects
  Future<List<Map<String, dynamic>>?> getSubjects({
    required String examGuid,
    required String schoolGuid,
    required String grade,
  }) async {
    try {
      final iv = SecureCrypto.generateIv();
      final ivBytes = base64.decode(iv);
      final params = jsonEncode({
        'examGuid': examGuid,
        'schoolGuid': schoolGuid,
        'grade': grade,
      });
      logger.debug('HTTP', 'Subjects bp 明文: $params');
      final bp = SecureCrypto.aesGcmEncrypt(params, ivBytes);
      final resp = await _dio.post(
        '${ApiConfig.baseScore}${ApiConfig.questionSubjects}',
        options: Options(headers: {
          'bn': iv,
          'bp': bp,
        }),
      );
      final d = _dataOf(resp.data);
      if (d is Map) {
        final list = d['list'];
        if (list is List) {
          logger.debug('HTTP', 'Subjects 解密字段: ${list.length} 个科目');
          return list.cast<Map<String, dynamic>>();
        }
      }
      return null;
    } catch (e) {
      logger.error('HTTP', 'getSubjects 失败', e);
      return null;
    }
  }
}