import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/web/webview_page.dart';
import 'package:sapat_cash/src/core/push/route_names.dart';

void main() {
  group('shouldReloadCurrentWebView', () {
    test('returns true when target url matches current url', () {
      expect(
        shouldReloadCurrentWebView(
          currentUri: Uri.parse('https://example.com/order?id=1'),
          targetUri: Uri.parse('https://example.com/order?id=1'),
        ),
        isTrue,
      );
    });

    test('returns false when target url differs from current url', () {
      expect(
        shouldReloadCurrentWebView(
          currentUri: Uri.parse('https://example.com/order?id=1'),
          targetUri: Uri.parse('https://example.com/order?id=2'),
        ),
        isFalse,
      );
    });
  });

  group('shouldRefreshWebViewOnRouteResume', () {
    test('returns true when webview becomes top route again', () {
      expect(
        shouldRefreshWebViewOnRouteResume(
          hasBeenTopRoute: true,
          previousTopRouteName: RouteNames.bindCard,
          currentTopRouteName: RouteNames.webView,
        ),
        isTrue,
      );
    });

    test('returns false when webview becomes top route for the first time', () {
      expect(
        shouldRefreshWebViewOnRouteResume(
          hasBeenTopRoute: false,
          previousTopRouteName: RouteNames.bindCard,
          currentTopRouteName: RouteNames.webView,
        ),
        isFalse,
      );
    });

    test('returns false when webview stays top route', () {
      expect(
        shouldRefreshWebViewOnRouteResume(
          hasBeenTopRoute: true,
          previousTopRouteName: RouteNames.webView,
          currentTopRouteName: RouteNames.webView,
        ),
        isFalse,
      );
    });

    test('returns false when another route becomes top route', () {
      expect(
        shouldRefreshWebViewOnRouteResume(
          hasBeenTopRoute: true,
          previousTopRouteName: RouteNames.webView,
          currentTopRouteName: RouteNames.bindCard,
        ),
        isFalse,
      );
    });
  });
}
