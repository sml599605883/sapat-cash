import 'dart:async';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../core/json/json.dart';
import '../../core/network/api/api_client.dart';
import '../../core/push/app_push.dart';
import '../../core/push/route_names.dart';
import '../auth/auth_controller.dart';
import '../main_tab/main_tab_controller.dart';

class RecreditTaskCoordinator {
  RecreditTaskCoordinator._();

  static final RecreditTaskCoordinator instance = RecreditTaskCoordinator._();

  static const Duration _pollInterval = Duration(seconds: 10);

  Timer? _pollTimer;
  String _productId = '';
  bool _handlingCompletion = false;

  bool get isRunning => _pollTimer != null;
  String get productId => _productId;

  void start({required String productId}) {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }
    _productId = normalizedProductId;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_poll());
    });
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _productId = '';
    _handlingCompletion = false;
  }

  Future<void> _poll() async {
    if (_productId.isEmpty || _handlingCompletion) {
      return;
    }

    final context = SapatCashApp.navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final authController = context.read<AuthController>();
    await authController.ensureInitialized();
    if (!authController.isLoggedIn) {
      stop();
      return;
    }

    try {
      final response = await apiService.reCredit();
      final earphone = Json(response.data)['earphone'].intOrNull ?? 0;
      if (earphone == 1) {
        await _handleCompletion();
      }
    } catch (_) {
      // Keep polling on transient failures. Background polling should stay silent.
    }
  }

  Future<void> _handleCompletion() async {
    if (_handlingCompletion) {
      return;
    }
    _handlingCompletion = true;
    final currentProductId = _productId;
    stop();

    final navigator = SapatCashApp.navigatorKey.currentState;
    final context = SapatCashApp.navigatorKey.currentContext;
    if (navigator == null || context == null || currentProductId.isEmpty) {
      return;
    }

    final currentRouteName = AppPush.currentRouteName();
    if (currentRouteName == RouteNames.waitingCredit) {
      await AppPush.clickApply(
        context,
        productId: currentProductId,
        removeRouteNamesOnSuccess: const <String>[RouteNames.waitingCredit],
      );
      return;
    }

    if (currentRouteName == RouteNames.mainTab) {
      final mainTabController = context.read<MainTabController>();
      if (mainTabController.currentIndex == 0) {
        mainTabController.switchToHome(refresh: true);
      }
    }
  }
}
