import 'package:flutter/widgets.dart';

import 'auth_cache.dart';

class AuthController extends ChangeNotifier {
  bool _initialized = false;
  bool _loggedIn = false;
  String _userToken = '';
  String _phone = '';
  Future<void>? _initializeFuture;

  bool get initialized => _initialized;
  bool get isLoggedIn => _loggedIn;
  String get userToken => _userToken;
  String get phone => _phone;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final current = _initializeFuture;
    if (current != null) {
      return current;
    }
    _initializeFuture = _loadInitialState();
    return _initializeFuture!;
  }

  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await initialize();
  }

  Future<void> _loadInitialState() async {
    _userToken = await AuthCache.getUserToken();
    _loggedIn = _userToken.trim().isNotEmpty;
    _phone = await AuthCache.getPhone();
    _initialized = true;
    _initializeFuture = null;
    notifyListeners();
  }

  Future<void> markLoggedIn({
    required String userToken,
    required String phone,
  }) async {
    _userToken = userToken.trim();
    _loggedIn = _userToken.isNotEmpty;
    _phone = phone;
    await AuthCache.setPhone(phone);
    await AuthCache.setUserToken(_userToken);
    notifyListeners();
  }

  Future<void> logout() async {
    _loggedIn = false;
    _userToken = '';
    await AuthCache.clear();
    notifyListeners();
  }
}
