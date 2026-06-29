import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sapat_cash/src/core/push/route_names.dart';
import 'package:sapat_cash/src/features/auth/auth_controller.dart';
import 'package:sapat_cash/src/features/auth/login_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _mockImageAssets();
  });

  testWidgets(
    'privacy agreement checkbox and policy link handle separate taps',
    (tester) async {
      final observer = _RecordingNavigatorObserver();
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthController(),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [observer],
            home: const LoginPage(),
          ),
        ),
      );

      expect(_checkboxAsset(tester), 'assets/image/login/checkbox_checked.png');

      final privacyText = find
          .byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Privacy Policy'),
          )
          .first;
      await tester.ensureVisible(privacyText);
      await tester.tapAt(tester.getCenter(privacyText) + const Offset(60, 0));
      await tester.pump();
      while (tester.takeException() != null) {}

      expect(observer.pushedRouteNames, contains(RouteNames.webView));

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      expect(_checkboxAsset(tester), 'assets/image/login/checkbox_checked.png');

      await tester.tap(find.byType(Image).last);
      await tester.pump();

      expect(
        _checkboxAsset(tester),
        'assets/image/login/checkbox_unchecked.png',
      );
    },
  );
}

String? _checkboxAsset(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image).last);
  final provider = image.image;
  return provider is AssetImage ? provider.assetName : null;
}

void _mockImageAssets() {
  const imageBytes = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
  ];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'AssetManifest.bin') {
          return const StandardMessageCodec().encodeMessage(<String, Object>{});
        }
        return ByteData.sublistView(Uint8List.fromList(imageBytes));
      });
}

final class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<String?> pushedRouteNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}
