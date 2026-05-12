import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/network/api/api_client.dart';
import '../../core/report/report_cache.dart';
import 'auth_controller.dart';

class LoginController extends ChangeNotifier {
  LoginController(this._authController);

  final AuthController _authController;

  bool _agreed = true;
  bool _sendingCode = false;
  bool _submitting = false;
  int _countdown = 0;
  Timer? _timer;

  bool get agreed => _agreed;
  bool get sendingCode => _sendingCode;
  bool get submitting => _submitting;
  int get countdown => _countdown;
  bool get canRequestCode => !_sendingCode && _countdown == 0;

  void toggleAgreement() {
    _agreed = !_agreed;
    notifyListeners();
  }

  bool isCodeValid(String code) {
    final normalized = code.replaceAll(RegExp(r'[^0-9]'), '');
    return normalized.length >= 4;
  }

  Future<void> requestSmsCode(String phone) async {
    _sendingCode = true;
    notifyListeners();
    try {
      await apiService.requestLoginSmsCode(phone: phone);
      _startCountdown();
    } finally {
      _sendingCode = false;
      notifyListeners();
    }
  }

  Future<void> login({required String phone, required String code}) async {
    _submitting = true;
    notifyListeners();
    try {
      final response = await apiService.loginOrRegisterByCode(
        phone: phone,
        code: code,
      );
      final userToken = response.json['nucleosyntheses'].stringValue;
      await ReportCache.setLoginAt(DateTime.now().millisecondsSinceEpoch);
      await _authController.markLoggedIn(userToken: userToken, phone: phone);
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _countdown = 59;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        _countdown = 0;
        timer.cancel();
      } else {
        _countdown--;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
