import 'package:flutter/widgets.dart';

import 'auth_cache.dart';

class AuthController extends ChangeNotifier {
  bool _initialized = false;
  bool _loggedIn = false;
  String _phone = '';

  bool get initialized => _initialized;
  bool get isLoggedIn => _loggedIn;
  String get phone => _phone;

  Future<void> initialize() async {
    _loggedIn = await AuthCache.isLoggedIn();
    _phone = await AuthCache.getPhone();
    _initialized = true;
    notifyListeners();
  }

  Future<void> markLoggedIn({required String phone}) async {
    _loggedIn = true;
    _phone = phone;
    await AuthCache.setLoggedIn(true);
    await AuthCache.setPhone(phone);
    notifyListeners();
  }

  Future<void> logout() async {
    _loggedIn = false;
    _phone = '';
    await AuthCache.clear();
    notifyListeners();
  }
}
