import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/core/network/config/network_bootstrapper.dart';
import 'package:sapat_cash/src/core/network/config/network_config.dart';

void main() {
  group('NetworkBootstrapper', () {
    test('decodes remote config returned as base64 json string', () async {
      final remotePayload = base64Encode(
        utf8.encode(
          jsonEncode(<String, String>{
            'api': 'https://api.example.com',
            'web': 'https://web.example.com',
          }),
        ),
      );
      final dio = Dio()
        ..httpClientAdapter = _FakeBootstrapAdapter(remotePayload);

      final result = await NetworkBootstrapper(dio).bootstrap();

      expect(result.apiBaseUrl, 'https://api.example.com');
      expect(result.webBaseUrl, 'https://web.example.com');
    });
  });
}

class _FakeBootstrapAdapter implements HttpClientAdapter {
  _FakeBootstrapAdapter(this.remotePayload);

  final String remotePayload;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.toString() == NetworkConfig.remoteConfigUrl) {
      return ResponseBody.fromString(
        remotePayload,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.textPlainContentType],
        },
      );
    }
    return ResponseBody.fromString('', 500);
  }
}
