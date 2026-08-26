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

  Future<bool> login(String phone, String code) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authService.loginByPhone(phone, code);
      if (user != null) {
        _user = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendSmsCode(String phone) async {
    return _authService.sendSmsCode(phone);
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}