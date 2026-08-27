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

  Future<void> init() async {
    final token = await DioClient().getToken();
    if (token != null && token.isNotEmpty) {
      _user = await _authService.getUserInfo();
    }
    _isInitialized = true;
    notifyListeners();
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