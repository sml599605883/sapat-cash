import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/core/push/route_names.dart';
import 'package:sapat_cash/src/features/main_tab/main_tab_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MainTabController app resume refresh', () {
    test('does not refresh home when login route is covering main tab', () {
      final controller = MainTabController(
        topRouteNameProvider: () => RouteNames.login,
      );

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(controller.homeRefreshToken, 0);
      expect(controller.mineRefreshToken, 0);
      controller.dispose();
    });

    test('refreshes home when main tab route is visible on resume', () {
      final controller = MainTabController(
        topRouteNameProvider: () => RouteNames.mainTab,
      );

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(controller.homeRefreshToken, 1);
      expect(controller.mineRefreshToken, 0);
      controller.dispose();
    });
  });
}
