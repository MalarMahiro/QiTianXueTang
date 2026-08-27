import 'dart:convert';
import '../models/user_model.dart';
import 'dio_client.dart';
import 'logger.dart';

/// 首页导航/宫格条目
class NavItem {
  final String name;
  final String headImgUrl;
  final String linkUrl;
  NavItem({required this.name, required this.headImgUrl, required this.linkUrl});
  factory NavItem.fromJson(Map<String, dynamic> j) => NavItem(
        name: j['name']?.toString() ?? '',
        headImgUrl: j['headImgUrl']?.toString() ?? '',
        linkUrl: j['linkUrl']?.toString() ?? '',
      );
}

/// 首页板块图
class PlateItem {
  final String mainTitle;
  final String subtTitle;
  final String url;
  final String image;
  PlateItem({required this.mainTitle, required this.subtTitle, required this.url, required this.image});
  factory PlateItem.fromJson(Map<String, dynamic> j) => PlateItem(
        mainTitle: j['mainTitle']?.toString() ?? '',
        subtTitle: j['subtTitle']?.toString() ?? '',
        url: j['url']?.toString() ?? '',
        image: j['image']?.toString() ?? '',
      );
}

/// 首页广告
class AdItem {
  final String imgLink;
  final String jumpLink;
  final String title;
  AdItem({required this.imgLink, required this.jumpLink, required this.title});
  factory AdItem.fromJson(Map<String, dynamic> j) => AdItem(
        imgLink: j['imgLink']?.toString() ?? '',
        jumpLink: j['jumpLink']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
      );
}

/// 首页服务：宫格导航/板块/广告/学情/消息
class HomeService {
  final DioClient _client = DioClient();

  /// 首页广告（positionCode 用原App首页宫格顶部广告位 9）
  Future<List<AdItem>> getAds(UserModel user) async {
    try {
      if (_ctxMissing(user)) return [];
      final raw = await _client.getAdInfo(
        positionCode: '9',
        cityCode: user.cityCode ?? '',
        ruCode: user.ruCode ?? '',
        grade: _g(user),
        schoolGuid: user.schoolGuid!,
        currentGrade: user.grade ?? _g(user),
      );
      if (raw == null) return [];
      return raw.map((e) => e is Map ? AdItem.fromJson(e.cast<String, dynamic>()) : null)
          .whereType<AdItem>().toList();
    } catch (e) {
      logger.error('Home', '广告失败', e);
      return [];
    }
  }

  /// 宫格导航。navigations 是 JSON 字符串数组
  Future<List<NavItem>> getNavigation(UserModel user) async {
    try {
      if (_ctxMissing(user)) return [];
      final raw = await _client.getNavigation(
        grade: _g(user), schoolGuid: user.schoolGuid!,
        ruCode: user.ruCode ?? '', cityCode: user.cityCode ?? '',
        currentGrade: user.grade ?? _g(user),
      );
      if (raw == null) return [];
      final list = <NavItem>[];
      for (final s in raw) {
        try {
          final m = (jsonDecode(s) as Map).cast<String, dynamic>();
          list.add(NavItem.fromJson(m));
        } catch (_) {}
      }
      return list;
    } catch (e) {
      logger.error('Home', '导航失败', e);
      return [];
    }
  }

  /// 板块图
  Future<List<PlateItem>> getPlates(UserModel user) async {
    try {
      if (_ctxMissing(user)) return [];
      final raw = await _client.getPlates(grade: _g(user), currentGrade: user.grade ?? _g(user));
      if (raw == null) return [];
      return raw.map((e) => e is Map ? PlateItem.fromJson(e.cast<String, dynamic>()) : null)
          .whereType<PlateItem>().toList();
    } catch (e) {
      logger.error('Home', '板块失败', e);
      return [];
    }
  }

  /// 学情数据
  Future<Map<String, dynamic>> getStatistical() async {
    try {
      final d = await _client.getStatistical();
      return d ?? {};
    } catch (e) {
      logger.error('Home', '学情失败', e);
      return {};
    }
  }

  /// 消息
  Future<Map<String, dynamic>> getMessageTop() async {
    try {
      final d = await _client.getMessageTop();
      return d ?? {};
    } catch (e) {
      logger.error('Home', '消息失败', e);
      return {};
    }
  }

  bool _ctxMissing(UserModel u) => u.schoolGuid == null || u.schoolGuid!.isEmpty;
  String _g(UserModel u) => u.grade ?? '';
}