import 'dart:convert';

import 'package:dio/dio.dart';

import '../../json/json.dart';
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
      final apiBaseUrl = payload['api'].stringOrNull ?? defaultApi;
      final webBaseUrl = payload['web'].stringOrNull ?? defaultWeb;
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

  Json _decodePayload(dynamic raw) {
    final direct = Json(raw);
    if (direct.mapOrNull != null) {
      return direct;
    }
    if (raw is String) {
      final trimmed = raw.trim();
      final parsed = Json.parse(trimmed);
      if (parsed.mapOrNull != null) {
        return parsed;
      }
      try {
        final decoded = Json.parseBytes(base64Decode(trimmed));
        if (decoded.mapOrNull != null) {
          return decoded;
        }
      } catch (_) {
        // Fall through to the empty payload below.
      }
    }
    return Json(<String, dynamic>{});
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
