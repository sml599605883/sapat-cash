import 'dart:convert';

import 'package:dio/dio.dart';

import 'network_config.dart';

class NetworkBootstrapper {
  NetworkBootstrapper(this._dio);

  final Dio _dio;

  Future<NetworkBootstrapResult> bootstrap() async {
    final defaultApi = NetworkConfig.defaultApiBaseUrl;
    final defaultWeb = NetworkConfig.defaultWebBaseUrl;

    if (await _isReachable(defaultApi)) {
      return NetworkBootstrapResult(
        apiBaseUrl: defaultApi,
        webBaseUrl: defaultWeb,
      );
    }

    try {
      final response = await _dio.get<dynamic>(NetworkConfig.remoteConfigUrl);
      final payload = _decodePayload(response.data);
      final apiBaseUrl = payload['apiBaseUrl'] as String? ?? defaultApi;
      final webBaseUrl = payload['webBaseUrl'] as String? ?? defaultWeb;
      return NetworkBootstrapResult(
        apiBaseUrl: apiBaseUrl,
        webBaseUrl: webBaseUrl,
      );
    } catch (_) {
      return NetworkBootstrapResult(
        apiBaseUrl: defaultApi,
        webBaseUrl: defaultWeb,
      );
    }
  }

  Future<bool> _isReachable(String url) async {
    try {
      final response = await _dio.get<dynamic>(url);
      return (response.statusCode ?? 500) < 500;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decodePayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is String) {
      final trimmed = raw.trim();
      try {
        return jsonDecode(trimmed) as Map<String, dynamic>;
      } catch (_) {
        final decoded = utf8.decode(base64Decode(trimmed));
        return jsonDecode(decoded) as Map<String, dynamic>;
      }
    }
    return <String, dynamic>{};
  }
}

class NetworkBootstrapResult {
  const NetworkBootstrapResult({
    required this.apiBaseUrl,
    required this.webBaseUrl,
  });

  final String apiBaseUrl;
  final String webBaseUrl;
}
