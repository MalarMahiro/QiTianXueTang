import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api.dart';
import 'logger.dart';
import 'qitian_crypto.dart';

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
        logger.debug('HTTP', '→ ${options.method} ${options.baseUrl}${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) async {
        logger.debug('HTTP', '← ${response.statusCode} ${response.requestOptions.path}');
        // 解密响应体: data.isEncrypt==true → AES解密 content
        try {
          final data = response.data;
          if (data is Map && data['data'] is Map) {
            final inner = data['data'] as Map;
            if (inner['isEncrypt'] == true && inner['content'] != null) {
              final decrypted =
                  QitianCrypto.aesEcbDecryptBase64(inner['content'].toString());
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
        return token;
      }
      logger.warn('HTTP', '← login data.token 为空: data=$d');
    } else {
      logger.warn('HTTP', '← login 响应结构异常: body=$body type=${body.runtimeType}');
    }
    return null;
  }

  /// 获取用户信息(响应AES加密, 解密后存 raw 字符串)
  Future<Map<String, dynamic>?> getUserInfoRaw() async {
    try {
      final resp = await _dio.get('${ApiConfig.baseUser}${ApiConfig.userInfo}');
      final body = resp.data;
      if (body is Map && body['status'] == 200 && body['data'] is Map) {
        final data = body['data'] as Map;
        // 若已解密且有 decryptedData 直接用
        if (data['decryptedData'] is Map) {
          return (data['decryptedData'] as Map).cast<String, dynamic>();
        }
        // 否则解析 content
        final content = data['content']?.toString();
        if (content != null && content.isNotEmpty) {
          final decoded = jsonDecode(content);
          return (decoded as Map).cast<String, dynamic>();
        }
      }
      return null;
    } catch (e) {
      logger.error('HTTP', '获取用户信息失败', e);
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    _memToken = token; // 先写内存，保证会话可用
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
}