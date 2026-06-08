import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/web/webview_bridge_constants.dart';
import 'package:sapat_cash/src/features/web/webview_bridge_dispatcher.dart';
import 'package:sapat_cash/src/features/web/webview_bridge_models.dart';

void main() {
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
}
