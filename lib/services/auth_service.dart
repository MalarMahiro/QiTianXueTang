import 'package:dio/dio.dart';
import '../../config/api.dart';
import '../../models/user_model.dart';
import 'dio_client.dart';

class AuthService {
  final DioClient _client = DioClient();

  Future<UserModel?> loginByPhone(String phone, String code) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.login,
        data: {'phone': phone, 'code': code, 'type': 'sms'},
      );
      if (response.data['code'] == 0 && response.data['data'] != null) {
        final user = UserModel.fromJson(response.data['data']);
        if (user.token != null) {
          await _client.saveToken(user.token!, user.refreshToken);
        }
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> sendSmsCode(String phone) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.smsCode,
        data: {'phone': phone, 'type': 'login'},
      );
      return response.data['code'] == 0;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> getUserInfo() async {
    try {
      final response = await _client.dio.get(ApiConfig.userInfo);
      if (response.data['code'] == 0) {
        return UserModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _client.clearToken();
  }
}