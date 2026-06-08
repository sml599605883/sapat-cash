import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/core/push/route_names.dart';
import 'package:sapat_cash/src/features/orders/order_list_page.dart';

void main() {
  group('shouldRefreshOrderListOnRouteResume', () {
    test('returns true when order list becomes top route again', () {
      expect(
        shouldRefreshOrderListOnRouteResume(
          hasBeenTopRoute: true,
          previousTopRouteName: RouteNames.bindCard,
          currentTopRouteName: RouteNames.orderList,
        ),
        isTrue,
      );
    });

    test('returns false when order list becomes top route for the first time', () {
      expect(
        shouldRefreshOrderListOnRouteResume(
          hasBeenTopRoute: false,
          previousTopRouteName: RouteNames.bindCard,
          currentTopRouteName: RouteNames.orderList,
        ),
        isFalse,
      );
    });

    test('returns false when order list stays top route', () {
      expect(
        shouldRefreshOrderListOnRouteResume(
          hasBeenTopRoute: true,
          previousTopRouteName: RouteNames.orderList,
          currentTopRouteName: RouteNames.orderList,
        ),
        isFalse,
      );
    });

    test('returns false when another route becomes top route', () {
      expect(
        shouldRefreshOrderListOnRouteResume(
          hasBeenTopRoute: true,
          previousTopRouteName: RouteNames.orderList,
          currentTopRouteName: RouteNames.bindCard,
        ),
        isFalse,
      );
    });
  });
}
