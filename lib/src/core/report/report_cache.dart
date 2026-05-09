import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'report_models.dart';

class ReportCache {
  const ReportCache._();

  static const _keyHasOpened = 'report.has_opened';
  static const _keyLoginAt = 'report.login_at';
  static const _keyAdjustInitialized = 'report.adjust_initialized';
  static const _keyAdjustLastStatus = 'report.adjust_last_status';
  static const _keyCachedLocation = 'report.cached_location';
  static const _keyLastMarketSignature = 'report.last_market_signature';
  static const _keyLastPushToken = 'report.last_push_token';
  static const _keySessionId = 'report.session_id';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<bool> markAppOpened() async {
    final prefs = await _prefs();
    final firstLaunch = !(prefs.getBool(_keyHasOpened) ?? false);
    await prefs.setBool(_keyHasOpened, true);
    return firstLaunch;
  }

  static Future<void> setLoginAt(int millis) async {
    final prefs = await _prefs();
    await prefs.setInt(_keyLoginAt, millis);
  }

  static Future<int> getLoginAt() async {
    final prefs = await _prefs();
    return prefs.getInt(_keyLoginAt) ?? 0;
  }

  static Future<bool> isAdjustInitialized() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyAdjustInitialized) ?? false;
  }

  static Future<void> setAdjustInitialized(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyAdjustInitialized, value);
  }

  static Future<void> setAdjustLastStatus(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyAdjustLastStatus, value);
  }

  static Future<String> getAdjustLastStatus() async {
    final prefs = await _prefs();
    return prefs.getString(_keyAdjustLastStatus) ?? '';
  }

  static Future<void> saveLocation(ReportLocation location) async {
    final prefs = await _prefs();
    await prefs.setString(
      _keyCachedLocation,
      jsonEncode(location.toCacheMap()),
    );
  }

  static Future<ReportLocation?> getLocation() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_keyCachedLocation);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final location = ReportLocation.fromCacheMap(decoded);
    return location.isValid ? location : null;
  }

  static Future<String> getLastMarketSignature() async {
    final prefs = await _prefs();
    return prefs.getString(_keyLastMarketSignature) ?? '';
  }

  static Future<void> setLastMarketSignature(String signature) async {
    final prefs = await _prefs();
    await prefs.setString(_keyLastMarketSignature, signature);
  }

  static Future<String> getLastPushToken() async {
    final prefs = await _prefs();
    return prefs.getString(_keyLastPushToken) ?? '';
  }

  static Future<void> setLastPushToken(String token) async {
    final prefs = await _prefs();
    await prefs.setString(_keyLastPushToken, token);
  }

  static Future<void> setSessionId(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keySessionId, value);
  }

  static Future<String> getSessionId() async {
    final prefs = await _prefs();
    return prefs.getString(_keySessionId) ?? '';
  }
}
