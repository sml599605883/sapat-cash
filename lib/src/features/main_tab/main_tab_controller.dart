import 'package:flutter/widgets.dart';

import '../../core/report/report_manager.dart';

class MainTabController extends ChangeNotifier with WidgetsBindingObserver {
  MainTabController() {
    WidgetsBinding.instance.addObserver(this);
  }

  int _currentIndex = 0;
  int _homeRefreshToken = 0;
  int _mineRefreshToken = 0;

  int get currentIndex => _currentIndex;
  int get homeRefreshToken => _homeRefreshToken;
  int get mineRefreshToken => _mineRefreshToken;

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
}
