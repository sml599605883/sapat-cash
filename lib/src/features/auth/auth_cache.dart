import 'package:shared_preferences/shared_preferences.dart';

class AuthCache {
  const AuthCache._();

  static const _keyLoggedIn = 'auth.logged_in';
  static const _keyPhone = 'auth.phone';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyLoggedIn, value);
  }

  static Future<String> getPhone() async {
    final prefs = await _prefs();
    return prefs.getString(_keyPhone) ?? '';
  }

  static Future<void> setPhone(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyPhone, value);
  }

  static Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyPhone);
  }
}
