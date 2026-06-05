import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/web/webview_page.dart';

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
}
