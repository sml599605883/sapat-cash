import 'dart:convert';

import '../../core/json/json.dart';

class WebViewBridgeRequest {
  const WebViewBridgeRequest({
    required this.action,
    required this.callbackId,
    required this.data,
    required this.rawData,
  });

  factory WebViewBridgeRequest.fromRawMessage(String rawMessage) {
    final json = Json.parse(rawMessage);
    return WebViewBridgeRequest.fromRawObject(json.rawValue);
  }

  factory WebViewBridgeRequest.fromRawObject(Object? rawObject) {
    final json = Json(rawObject);
    final map = json.mapValue;
    final data = _readData(map);
    return WebViewBridgeRequest(
      action: _readString(map, const ['action', 'name']),
      callbackId: _readString(map, const ['callbackId', 'callback', 'id']),
      data: data,
      rawData: map['data'] ?? map['payload'] ?? map['params'],
    );
  }

  final String action;
  final String callbackId;
  final Map<String, dynamic> data;
  final Object? rawData;

  bool get expectsCallback => callbackId.trim().isNotEmpty;

  String get rawDataString {
    final raw = rawData;
    if (raw == null) {
      return '';
    }
    if (raw is String) {
      return raw.trim();
    }
    return Json(raw).stringOrNull?.trim() ?? '';
  }

  static Map<String, dynamic> _readData(Map<String, dynamic> source) {
    final raw = source['data'] ?? source['payload'] ?? source['params'];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return Json.parse(raw).mapValue;
    }
    return <String, dynamic>{};
  }

  static String _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = Json(source[key]).stringOrNull?.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}

class WebViewBridgeResult {
  const WebViewBridgeResult({
    required this.code,
    required this.message,
    this.data = const <String, dynamic>{},
  });

  factory WebViewBridgeResult.success([
    Map<String, dynamic> data = const <String, dynamic>{},
  ]) {
    return WebViewBridgeResult(code: 0, message: 'success', data: data);
  }

  factory WebViewBridgeResult.failure(
    String message, {
    int code = -1,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) {
    return WebViewBridgeResult(code: code, message: message, data: data);
  }

  final int code;
  final String message;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'code': code, 'message': message, 'data': data};
  }

  String encode() => jsonEncode(toJson());
}
