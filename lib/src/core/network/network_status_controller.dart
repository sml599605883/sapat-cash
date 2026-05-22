import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

class NetworkStatusController extends ChangeNotifier {
  bool _initialized = false;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get initialized => _initialized;
  bool get isOffline => _isOffline;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await _refreshStatus();
    _subscription = Connectivity().onConnectivityChanged.listen((_) {
      unawaited(_refreshStatus());
    });
  }

  Future<void> _refreshStatus() async {
    final isOffline = await _detectOffline();
    if (_isOffline == isOffline) {
      return;
    }
    _isOffline = isOffline;
    notifyListeners();
  }

  Future<bool> _detectOffline() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasTransport = connectivityResults.any(
      (item) => item != ConnectivityResult.none,
    );
    if (!hasTransport) {
      return true;
    }

    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isEmpty || result.first.rawAddress.isEmpty;
    } on SocketException {
      return true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
