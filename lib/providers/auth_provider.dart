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

  /// 供下拉刷新等主动触发：重新拉取完整用户信息
  Future<void> refreshUserInfo() => _refreshUserInfo();

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

  /// 编辑昵称：调用服务端并本地更新
  Future<bool> updateNickname(String nickName) async {
    try {
      final d = await DioClient().updateNickname(nickName);
      if (d != null) {
        // 服务端返回 auditNickName/nickName，优先取 nickName
        final newName = d['nickName']?.toString() ?? nickName;
        if (_user != null) {
          _user = UserModel(
            userId: _user!.userId,
            phone: _user!.phone,
            nickname: newName,
            avatar: _user!.avatar,
            token: _user!.token,
            refreshToken: _user!.refreshToken,
            gradeId: _user!.gradeId,
            gradeName: _user!.gradeName,
            schoolName: _user!.schoolName,
            cityName: _user!.cityName,
            schoolGuid: _user!.schoolGuid,
            grade: _user!.grade,
            ruCode: _user!.ruCode,
            cityCode: _user!.cityCode,
            studentName: _user!.studentName,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}