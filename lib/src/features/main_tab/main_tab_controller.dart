import 'package:flutter/widgets.dart';

import '../../core/push/route_names.dart';
import '../../core/report/report_manager.dart';

class MainTabController extends ChangeNotifier with WidgetsBindingObserver {
  MainTabController({String? Function()? topRouteNameProvider})
    : _topRouteNameProvider = topRouteNameProvider {
    WidgetsBinding.instance.addObserver(this);
  }

  final String? Function()? _topRouteNameProvider;

  int _currentIndex = 0;
  int _homeRefreshToken = 0;
  int _mineRefreshToken = 0;

  int get currentIndex => _currentIndex;
  int get homeRefreshToken => _homeRefreshToken;
  int get mineRefreshToken => _mineRefreshToken;

  void switchToHome({bool refresh = false}) {
    var shouldNotify = false;

    if (_currentIndex != 0) {
      _currentIndex = 0;
      shouldNotify = true;
    }

    if (refresh) {
      _homeRefreshToken++;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  void onTabTap(int index) {
    if (_currentIndex == index) {
      return;
    }

    if (index == 0) {
      _homeRefreshToken++;
    } else if (index == 1) {
      _mineRefreshToken++;
    }

    _currentIndex = index;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    ReportManager.instance.onAppResumed();
    if (!_isMainTabRouteVisible()) {
      return;
    }
    if (_currentIndex == 0) {
      _homeRefreshToken++;
    } else if (_currentIndex == 1) {
      _mineRefreshToken++;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isMainTabRouteVisible() {
    final routeName = _topRouteNameProvider?.call()?.trim();
    if (routeName == null || routeName.isEmpty) {
      return true;
    }
    return routeName == RouteNames.mainTab;
  }
}
