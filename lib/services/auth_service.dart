import '../../models/user_model.dart';
import 'dio_client.dart';
import 'logger.dart';

class AuthService {
  final DioClient _client = DioClient();

  /// 密码登录：POST szone-my.7net.cc/login (form)，登录成功后拉取个人信息
  Future<UserModel?> loginByPassword(String userCode, String password) async {
    final token = await _client.login(userCode, password);
    if (token == null) return null;
    // 尝试拉取完整个人信息（GetUserInfo），失败则回退为仅有token的最小信息
    UserModel? user;
    try {
      user = await getUserInfo();
    } catch (_) {}
    user ??= UserModel(userId: userCode, token: token, phone: userCode);
    logger.info('Auth', '登录成功: $userCode');
    return user;
  }

  /// 获取用户信息：GET szone-my.7net.cc/userInfo/GetUserInfo
  /// 响应为 AES 加密，dio_client 已解密。
  Future<UserModel?> getUserInfo() async {
    try {
      logger.info('Auth', '获取用户信息');
      final raw = await _client.getUserInfoRaw();
      if (raw == null) return null;
      final token = await _client.getToken();
      return UserModel.fromJson(raw).copyWith(token: token);
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