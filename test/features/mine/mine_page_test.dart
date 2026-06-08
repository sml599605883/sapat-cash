import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sapat_cash/src/core/json/json.dart';
import 'package:sapat_cash/src/features/auth/auth_controller.dart';
import 'package:sapat_cash/src/features/main_tab/main_tab_controller.dart';
import 'package:sapat_cash/src/features/mine/mine_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MinePage startup refresh', () {
    testWidgets('does not fetch popup when mounted offstage on home tab', (
      tester,
    ) async {
      var popupFetchCount = 0;
      final controller = MainTabController();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp(
            home: _MinePageHarness(
              currentIndex: 0,
              fetchPopupPayload: () async {
                popupFetchCount++;
                return Json({'refortification': ''});
              },
            ),
          ),
        ),
      );

        await tester.pump();
        await tester.pump();
        while (tester.takeException() != null) {}

        expect(popupFetchCount, 0);
        controller.dispose();
    });

    testWidgets('fetches popup when mine tab is the visible startup tab', (
      tester,
    ) async {
      var popupFetchCount = 0;
      final controller = MainTabController();
      controller.onTabTap(1);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp(
            home: ChangeNotifierProvider(
              create: (_) => AuthController(),
              child: MinePage(
                fetchPopupPayload: () async {
                  popupFetchCount++;
                  return Json({'refortification': ''});
                },
                showPopup: (_, popupPayload) async {
                  expect(popupPayload, isA<Json>());
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      while (tester.takeException() != null) {}

      expect(popupFetchCount, 1);
      controller.dispose();
    });
  });
}

class _MinePageHarness extends StatelessWidget {
  const _MinePageHarness({
    required this.currentIndex,
    required this.fetchPopupPayload,
  });

  final int currentIndex;
  final Future<Json> Function() fetchPopupPayload;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      children: [
        const SizedBox.shrink(),
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthController()),
          ],
          child: MinePage(
            fetchPopupPayload: fetchPopupPayload,
            showPopup: (_, popupPayload) async {
              expect(popupPayload, isA<Json>());
            },
          ),
        ),
      ],
    );
  }
}
