import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/core/push/app_push.dart';
import 'package:sapat_cash/src/core/push/route_names.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('AppPush apply success route cleanup', () {
    test('merges waiting credit cleanup into existing route removals', () {
      final routeNames = AppPush.mergeRouteNamesForTest(
        const [RouteNames.webView, RouteNames.waitingCredit],
        const [RouteNames.waitingCredit, RouteNames.bindCard],
      );

      expect(
        routeNames,
        containsAll(<String>[
          RouteNames.webView,
          RouteNames.waitingCredit,
          RouteNames.bindCard,
        ]),
      );
      expect(
        routeNames.where((name) => name == RouteNames.waitingCredit).length,
        1,
      );
    });

    test('clears all verification flow history when reopening identity step', () {
      final routeNames = AppPush.verificationFlowHistoryForTest(
        RouteNames.identityVerification,
      );

      expect(
        routeNames,
        containsAll(<String>[
          RouteNames.identityVerification,
          RouteNames.bindCard,
          RouteNames.waitingCredit,
          RouteNames.webView,
        ]),
      );
    });

    test('clears all verification flow history when opening webview', () {
      final routeNames = AppPush.pushWebViewCleanupRouteNamesForTest(
        const <String>[],
      );

      expect(
        routeNames,
        containsAll(<String>[
          RouteNames.identityVerification,
          RouteNames.bindCard,
          RouteNames.waitingCredit,
          RouteNames.webView,
        ]),
      );
    });

    test('includes change-account cleanup names when reopening webview', () {
      final routeNames = AppPush.changeAccountCleanupRouteNames(
        const <String>[RouteNames.webView, RouteNames.bindCard],
      );

      expect(
        routeNames,
        containsAll(<String>[
          RouteNames.webView,
          RouteNames.bindCard,
          RouteNames.bankAccountList,
        ]),
      );
      expect(routeNames.where((name) => name == RouteNames.webView).length, 1);
    });

    test('deduplicates change-account cleanup route names', () {
      final routeNames = AppPush.changeAccountCleanupRouteNames(
        const <String>[
          RouteNames.webView,
          RouteNames.bindCard,
          RouteNames.bankAccountList,
        ],
      );

      expect(routeNames.where((name) => name == RouteNames.webView).length, 1);
      expect(routeNames.where((name) => name == RouteNames.bindCard).length, 1);
      expect(
        routeNames.where((name) => name == RouteNames.bankAccountList).length,
        1,
      );
    });
  });

  group('AppPush location permission flow', () {
    test('requests permission when service is enabled but status is denied', () {
      expect(
        AppPush.locationPermissionActionForTest(
          serviceStatus: ServiceStatus.enabled,
          permissionStatus: PermissionStatus.denied,
        ),
        AppPushLocationPermissionAction.requestPermission,
      );
    });

    test('opens service prompt when location service is disabled', () {
      expect(
        AppPush.locationPermissionActionForTest(
          serviceStatus: ServiceStatus.disabled,
          permissionStatus: PermissionStatus.denied,
        ),
        AppPushLocationPermissionAction.openServicePrompt,
      );
    });

    test(
      'opens settings prompt when permission is permanently denied or restricted',
      () {
        expect(
          AppPush.locationPermissionActionForTest(
            serviceStatus: ServiceStatus.enabled,
            permissionStatus: PermissionStatus.permanentlyDenied,
          ),
          AppPushLocationPermissionAction.openSettingsPrompt,
        );
        expect(
          AppPush.locationPermissionActionForTest(
            serviceStatus: ServiceStatus.enabled,
            permissionStatus: PermissionStatus.restricted,
          ),
          AppPushLocationPermissionAction.openSettingsPrompt,
        );
      },
    );

    test('continues immediately when permission is already granted', () {
      expect(
        AppPush.locationPermissionActionForTest(
          serviceStatus: ServiceStatus.enabled,
          permissionStatus: PermissionStatus.granted,
        ),
        AppPushLocationPermissionAction.proceed,
      );
    });
  });
}
