import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/core/push/push_click_route_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushClickRouteHandler', () {
    setUp(() {
      PushClickRouteHandler.instance.clearPendingRoutesForTest();
    });

    test('ignores empty routes in test enqueue helper', () {
      final handler = PushClickRouteHandler.instance;

      handler.enqueueForTest('');
      handler.enqueueForTest('   ');

      expect(handler.pendingRouteCount, 0);
    });

    testWidgets('keeps pending routes when navigator is not ready', (
      tester,
    ) async {
      final handler = PushClickRouteHandler.instance;
      handler.enqueueForTest('ph://sapat-cash/ios/PhenologiesCommunicative');

      await handler.flushPendingRoutesForTest();

      expect(handler.pendingRouteCount, 1);
    });
  });
}
