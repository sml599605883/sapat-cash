import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/core/network/core/network_client.dart';
import 'package:sapat_cash/src/core/network/core/network_manager.dart';
import 'package:sapat_cash/src/core/network/core/network_response.dart';
import 'package:sapat_cash/src/core/network/core/response_parser.dart';

void main() {
  group('NetworkManager auth expired handling', () {
    test('treats legacy -2 code as auth expired without rethrowing', () async {
      var authExpiredCallCount = 0;
      final manager = NetworkManager(
        client: NetworkClient(dio: Dio()..httpClientAdapter = _MockAdapter(-2)),
        responseParser: const ResponseParser(),
        onAuthExpired: () async {
          authExpiredCallCount++;
        },
      );

      await expectLater(
        manager.get('/test'),
        completion(
          isA<NetworkResponse<dynamic>>().having((response) => response.code, 'code', -2),
        ),
      );
      expect(authExpiredCallCount, 1);
    });

  });
}

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.code);

  final int code;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = jsonEncode({
      'alligators': code,
      'cyanogenetic': 'auth expired',
      'evaginate': null,
    });
    return ResponseBody.fromString(
      body,
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}
