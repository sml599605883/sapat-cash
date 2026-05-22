import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/web/webview_bridge_models.dart';

void main() {
  group('WebViewBridgeRequest', () {
    test('parses action callback and nested data', () {
      final request = WebViewBridgeRequest.fromRawMessage(
        jsonEncode(<String, dynamic>{
          'action': 'requestCommonParams',
          'callbackId': 'cb_1',
          'data': <String, dynamic>{'scene': 'apply'},
        }),
      );

      expect(request.action, 'requestCommonParams');
      expect(request.callbackId, 'cb_1');
      expect(request.data, <String, dynamic>{'scene': 'apply'});
      expect(request.expectsCallback, isTrue);
    });

    test('parses string payload aliases', () {
      final request = WebViewBridgeRequest.fromRawMessage(
        jsonEncode(<String, dynamic>{
          'name': 'openScheme',
          'id': 'cb_2',
          'payload': jsonEncode(<String, dynamic>{'scheme': 'tel:123'}),
        }),
      );

      expect(request.action, 'openScheme');
      expect(request.callbackId, 'cb_2');
      expect(request.data, <String, dynamic>{'scheme': 'tel:123'});
    });
  });

  group('WebViewBridgeResult', () {
    test('encodes stable callback structure', () {
      final result = WebViewBridgeResult.success(const <String, dynamic>{
        'token': 'abc',
      });

      expect(jsonDecode(result.encode()), <String, dynamic>{
        'code': 0,
        'message': 'success',
        'data': <String, dynamic>{'token': 'abc'},
      });
    });
  });
}
