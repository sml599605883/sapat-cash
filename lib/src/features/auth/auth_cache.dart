import 'package:shared_preferences/shared_preferences.dart';

class AuthCache {
  const AuthCache._();

  static const _keyUserToken = 'auth.user_token';
  static const _keyPhone = 'auth.phone';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<bool> isLoggedIn() async {
    return (await getUserToken()).trim().isNotEmpty;
  }

  static Future<String> getUserToken() async {
    final prefs = await _prefs();
    return prefs.getString(_keyUserToken) ?? '';
  }

  static Future<void> setUserToken(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyUserToken, value);
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
    await prefs.remove(_keyUserToken);
  }
}
