import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/web/webview_bridge_constants.dart';
import 'package:sapat_cash/src/features/web/webview_bridge_dispatcher.dart';
import 'package:sapat_cash/src/features/web/webview_bridge_models.dart';

void main() {
  const reportMethodChannel = MethodChannel('sapat_cash/report_method');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(reportMethodChannel, null);
  });

  testWidgets('openScheme opens http links in a new app webview', (
    tester,
  ) async {
    BuildContext? context;
    String? reloadedUrl;
    String? pushedUrl;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final result = await WebViewBridgeDispatcher.dispatch(
      context: context!,
      request: const WebViewBridgeRequest(
        action: WebViewBridgeActionNames.openScheme,
        callbackId: '',
        data: <String, dynamic>{'url': 'https://example.com/order?id=1'},
        rawData: <String, dynamic>{'url': 'https://example.com/order?id=1'},
      ),
      goBackInWebView: () async => false,
      reloadOrOpenInWebView: (url) async {
        reloadedUrl = url;
      },
      openInNewWebView: (url) async {
        pushedUrl = url;
      },
    );

    expect(result.code, 0);
    expect(result.message, 'success');
    expect(reloadedUrl, isNull);
    expect(pushedUrl, 'https://example.com/order?id=1');
  });

  testWidgets(
    'toGrade requests native review on ios',
    (tester) async {
    BuildContext? context;
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(reportMethodChannel, (call) async {
          methods.add(call.method);
          return null;
        });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final result = await WebViewBridgeDispatcher.dispatch(
      context: context!,
      request: const WebViewBridgeRequest(
        action: WebViewBridgeActionNames.toGrade,
        callbackId: '',
        data: <String, dynamic>{},
        rawData: <String, dynamic>{},
      ),
      goBackInWebView: () async => false,
      reloadOrOpenInWebView: (_) async {},
      openInNewWebView: (_) async {},
    );

    expect(result.code, 0);
    expect(result.message, 'success');
    expect(methods, ['requestAppReview']);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'toGrade stays empty on android',
    (tester) async {
    BuildContext? context;
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(reportMethodChannel, (call) async {
          methods.add(call.method);
          return null;
        });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final result = await WebViewBridgeDispatcher.dispatch(
      context: context!,
      request: const WebViewBridgeRequest(
        action: WebViewBridgeActionNames.toGrade,
        callbackId: '',
        data: <String, dynamic>{},
        rawData: <String, dynamic>{},
      ),
      goBackInWebView: () async => false,
      reloadOrOpenInWebView: (_) async {},
      openInNewWebView: (_) async {},
    );

    expect(result.code, 0);
    expect(result.message, 'success');
    expect(methods, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
