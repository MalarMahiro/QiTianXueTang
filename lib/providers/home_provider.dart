import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/home_service.dart';

class HomeProvider extends ChangeNotifier {
  final HomeService _service = HomeService();
  List<NavItem> _navs = [];
  List<PlateItem> _plates = [];
  List<AdItem> _ads = [];
  String _studyTotalHour = '';
  int _collectionQuantity = 0;
  int _noReadMessage = 0;
  bool _loading = false;

  List<NavItem> get navs => _navs;
  List<PlateItem> get plates => _plates;
  List<AdItem> get ads => _ads;
  String get studyTotalHour => _studyTotalHour;
  int get collectionQuantity => _collectionQuantity;
  int get noReadMessage => _noReadMessage;
  bool get loading => _loading;

  Future<void> loadAll(UserModel user) async {
    _loading = true;
    notifyListeners();
    final results = await Future.wait([
      _service.getNavigation(user),
      _service.getPlates(user),
      _service.getAds(user),
      _service.getStatistical(),
      _service.getMessageTop(),
    ]);
    _navs = results[0] as List<NavItem>;
    _plates = results[1] as List<PlateItem>;
    _ads = results[2] as List<AdItem>;
    final stat = results[3] as Map<String, dynamic>;
    final msg = results[4] as Map<String, dynamic>;
    _studyTotalHour = stat['studyTotalHour']?.toString() ?? '';
    _collectionQuantity = (stat['collectionQuantity'] as num?)?.toInt() ?? 0;
    _noReadMessage = (msg['noReadNumber'] as num?)?.toInt() ?? 0;
    _loading = false;
    notifyListeners();
  }
}