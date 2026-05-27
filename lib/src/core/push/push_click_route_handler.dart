import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../app/app.dart';
import '../json/json.dart';
import '../report/report_native_bridge.dart';
import 'app_push.dart';

class PushClickRouteHandler {
  PushClickRouteHandler._();

  static final PushClickRouteHandler instance = PushClickRouteHandler._();

  final List<String> _pendingRoutes = <String>[];
  StreamSubscription<Json>? _nativeEventSubscription;
  bool _navigatorReadyObserverAttached = false;
  bool _isHandlingRoute = false;

  void bind() {
    _nativeEventSubscription ??= ReportNativeBridge.nativeEvents().listen((
      event,
    ) {
      if (event['type'].stringValue != 'push_route') {
        return;
      }
      final url = event['url'].stringValue.trim();
      if (url.isEmpty) {
        return;
      }
      _pendingRoutes.add(url);
      _flushPendingRoutesIfPossible();
    });
    _attachNavigatorReadyObserverIfNeeded();
    _flushPendingRoutesIfPossible();
  }

  @visibleForTesting
  void enqueueForTest(String url) {
    final normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) {
      return;
    }
    _pendingRoutes.add(normalizedUrl);
  }

  @visibleForTesting
  int get pendingRouteCount => _pendingRoutes.length;

  @visibleForTesting
  Future<void> flushPendingRoutesForTest() => _flushPendingRoutesIfPossible();

  @visibleForTesting
  void clearPendingRoutesForTest() {
    _pendingRoutes.clear();
  }

  Future<void> _flushPendingRoutesIfPossible() async {
    if (_isHandlingRoute) {
      return;
    }
    final navigator = SapatCashApp.navigatorKey.currentState;
    final context = SapatCashApp.navigatorKey.currentContext;
    if (navigator == null || context == null || !context.mounted) {
      _attachNavigatorReadyObserverIfNeeded();
      return;
    }

    _isHandlingRoute = true;
    try {
      while (_pendingRoutes.isNotEmpty) {
        final url = _pendingRoutes.removeAt(0);
        await AppPush.openWebUriWithNavigator(navigator, rawUrl: url);
      }
    } finally {
      _isHandlingRoute = false;
    }
  }

  void _attachNavigatorReadyObserverIfNeeded() {
    if (_navigatorReadyObserverAttached) {
      return;
    }
    _navigatorReadyObserverAttached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorReadyObserverAttached = false;
      unawaited(_flushPendingRoutesIfPossible());
    });
  }
}
