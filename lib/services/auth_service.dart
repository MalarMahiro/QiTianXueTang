import '../../config/api.dart';
import '../../models/user_model.dart';
import 'dio_client.dart';
import 'logger.dart';

class AuthService {
  final DioClient _client = DioClient();

  Future<UserModel?> loginByPhone(String phone, String code) async {
    try {
      logger.info('Auth', '尝试登录: $phone');
      final response = await _client.dio.post(
        ApiConfig.login,
        data: {'phone': phone, 'code': code, 'type': 'sms'},
      );
      if (response.data['code'] == 0 && response.data['data'] != null) {
        final user = UserModel.fromJson(response.data['data']);
        if (user.token != null) {
          await _client.saveToken(user.token!, user.refreshToken);
        }
        logger.info('Auth', '登录成功: ${user.name} / ${user.id}');
        return user;
      }
      logger.warn('Auth', '登录失败: code=${response.data['code']} msg=${response.data['msg']}');
      return null;
    } catch (e) {
      logger.error('Auth', '登录异常', e);
      return null;
    }
  }

  Future<bool> sendSmsCode(String phone) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.smsCode,
        data: {'phone': phone, 'type': 'login'},
      );
      final ok = response.data['code'] == 0;
      logger.info('Auth', '发送验证码: $phone -> $ok');
      return ok;
    } catch (e) {
      logger.error('Auth', '发送验证码异常', e);
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
    } catch (e) {
      logger.error('Auth', '获取用户信息异常', e);
      return null;
    }
  }

  Future<void> logout() async {
    await _client.clearToken();
    logger.info('Auth', '已退出登录');
  }
}