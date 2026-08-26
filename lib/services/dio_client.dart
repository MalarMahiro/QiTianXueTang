import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api.dart';

/// 封装Dio HTTP客户端
/// Ponytail: 统一拦截器处理token刷新和错误码
class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  DioClient._internal();
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  Dio get dio => _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final retryResponse = await _retry(error.requestOptions);
            handler.resolve(retryResponse);
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;
      final response = await Dio().post(
        '${ApiConfig.baseUrl}${ApiConfig.refreshToken}',
        data: {'refreshToken': refreshToken},
      );
      if (response.data['code'] == 0) {
        final newToken = response.data['data']['token']?.toString();
        final newRefresh = response.data['data']['refreshToken']?.toString();
        if (newToken != null) {
          await _storage.write(key: _tokenKey, value: newToken);
          if (newRefresh != null) {
            await _storage.write(key: _refreshTokenKey, value: newRefresh);
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> saveToken(String token, [String? refreshToken]) async {
    await _storage.write(key: _tokenKey, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
}