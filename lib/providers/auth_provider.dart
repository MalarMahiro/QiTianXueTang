import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/dio_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user?.isLoggedIn ?? false;
  bool get isInitialized => _isInitialized;

  /// 应用启动恢复会话：
  /// 只要有 token 就立即标记为已登录（登录状态不丢失），随后后台拉取完整信息增强。
  Future<void> init() async {
    final token = await DioClient().getToken();
    if (token != null && token.isNotEmpty) {
      // 先用 token 构造最小用户，保证 isLoggedIn=true，避免重启后掉登录
      _user = UserModel(userId: '', token: token);
      notifyListeners();
      // 协商会话密钥并拉取完整信息（失败不影响已登录状态）
      unawaited(_refreshUserInfo());
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _refreshUserInfo() async {
    try {
      final user = await _authService.getUserInfo();
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 密码登录：phone=手机号, password=明文密码（底层会加密）
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authService.loginByPassword(phone, password);
      _isLoading = false;
      notifyListeners();
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}