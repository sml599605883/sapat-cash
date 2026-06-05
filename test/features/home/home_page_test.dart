import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sapat_cash/src/core/json/json.dart';
import 'package:sapat_cash/src/features/home/home_models.dart';
import 'package:sapat_cash/src/features/home/home_page.dart';
import 'package:sapat_cash/src/features/main_tab/main_tab_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomePage refresh popup handling', () {
    testWidgets(
      'dismisses loading before waiting for popup to close',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 3200);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final popupCompleter = Completer<void>();
        var popupShown = false;

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => MainTabController(),
            child: MaterialApp(
              builder: (context, child) {
                final easyLoadingBuilder = EasyLoading.init();
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: easyLoadingBuilder(context, child),
                );
              },
              home: HomePage(
                fetchHomeData: () async => AppHomeResponse(
                  icon: const HomeIconEntry(imageUrl: '', link: ''),
                ),
                fetchPopupPayload: () async => Json({
                  'refortification': '3',
                  'haem': {'antagonist': 'https://example.com/popup.png'},
                }),
                showPopup: (_, popupPayload) {
                  expect(popupPayload, isA<Json>());
                  popupShown = true;
                  return popupCompleter.future;
                },
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();
        while (tester.takeException() != null) {}

        expect(popupShown, isTrue);
        expect(EasyLoading.isShow, isFalse);

        popupCompleter.complete();
        await tester.pumpAndSettle();
      },
    );
  });
}
