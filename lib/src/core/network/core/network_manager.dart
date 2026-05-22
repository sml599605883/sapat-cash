import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../config/network_bootstrapper.dart';
import '../config/network_config.dart';
import '../crypto/encryption_helper.dart';
import '../protocol/common_param_keys.dart';
import '../protocol/common_param_provider.dart';
import '../protocol/signature_helper.dart';
import 'business_exception.dart';
import 'network_client.dart';
import 'network_response.dart';
import 'response_parser.dart';

enum RequestMethod { get, post, upload }

class NetworkManager {
  NetworkManager({
    required NetworkClient client,
    required ResponseParser responseParser,
    this.asyncCommonParamProvider,
    this.syncCommonParamProvider,
    this.staticCommonParamProvider = const StaticCommonParamProvider({}),
  }) : _client = client,
       _responseParser = responseParser,
       _bootstrapper = NetworkBootstrapper(client.rawDio),
       _encryptionHelper = EncryptionHelper(
         key: NetworkConfig.encryptionKey,
         iv: NetworkConfig.encryptionIv,
       );

  final NetworkClient _client;
  final ResponseParser _responseParser;
  final AsyncCommonParamProvider? asyncCommonParamProvider;
  final SyncCommonParamProvider? syncCommonParamProvider;
  final StaticCommonParamProvider staticCommonParamProvider;
  final NetworkBootstrapper _bootstrapper;
  final EncryptionHelper _encryptionHelper;

  bool _handlingAuthExpired = false;
  String _apiBaseUrl = NetworkConfig.defaultApiBaseUrl;
  String _webBaseUrl = NetworkConfig.defaultWebBaseUrl;

  String get apiBaseUrl => _apiBaseUrl;
  String get webBaseUrl => _webBaseUrl;

  Future<void> initialize() async {
    final result = await _bootstrapper.bootstrap();
    _apiBaseUrl = result.apiBaseUrl;
    _webBaseUrl = result.webBaseUrl;
  }

  Future<NetworkResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: RequestMethod.get,
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<NetworkResponse<dynamic>> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) {
    return _request(
      method: RequestMethod.post,
      path: path,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<NetworkResponse<dynamic>> upload(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
    String? filePath,
    String fileField = 'file',
  }) {
    return _request(
      method: RequestMethod.upload,
      path: path,
      queryParameters: queryParameters,
      body: body,
      filePath: filePath,
      fileField: fileField,
    );
  }

  Future<NetworkResponse<dynamic>> encryptedReport(
    String path, {
    String? encryptedPayload,
    Object? rawPayload,
  }) {
    final payload =
        encryptedPayload ??
        _encryptionHelper.encryptText(jsonEncode(rawPayload ?? const {}));
    return post(path, body: {'payload': payload});
  }

  Future<Map<String, dynamic>> resolveCommonParams() {
    return _resolveCommonParams();
  }

  Future<Map<String, dynamic>> resolveMappedCommonParams({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final commonParams = await _resolveCommonParams();
    return _mapCommonParams(
      commonParams,
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<NetworkResponse<dynamic>> _request({
    required RequestMethod method,
    required String path,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
    String? filePath,
    String fileField = 'file',
  }) async {
    final commonParams = await _resolveCommonParams();
    final query = _mapCommonParams(
      commonParams,
      path: path,
      queryParameters: queryParameters,
    );

    late final Response<dynamic> response;

    switch (method) {
      case RequestMethod.get:
        response = await _client.rawDio.get<dynamic>(
          '$_apiBaseUrl$path',
          queryParameters: query,
        );
      case RequestMethod.post:
        response = await _client.rawDio.post<dynamic>(
          '$_apiBaseUrl$path',
          queryParameters: query,
          data: body,
        );
      case RequestMethod.upload:
        if (filePath == null ||
            filePath.isEmpty ||
            !File(filePath).existsSync()) {
          response = await _client.rawDio.post<dynamic>(
            '$_apiBaseUrl$path',
            queryParameters: query,
            data: body,
          );
        } else {
          final formData = FormData.fromMap({
            ...?body,
            fileField: await MultipartFile.fromFile(filePath),
          });
          response = await _client.rawDio.post<dynamic>(
            '$_apiBaseUrl$path',
            queryParameters: query,
            data: formData,
          );
        }
    }

    return _handleResponse(response.data);
  }

  Future<Map<String, dynamic>> _resolveCommonParams() async {
    if (asyncCommonParamProvider case final provider?) {
      return provider.getCommonParams();
    }
    if (syncCommonParamProvider case final provider?) {
      return provider.getCommonParams();
    }
    return staticCommonParamProvider.getCommonParams();
  }

  Map<String, dynamic> _mapCommonParams(
    Map<String, dynamic> source, {
    required String path,
    Map<String, dynamic>? queryParameters,
  }) {
    final mapped = <String, dynamic>{};
    for (final entry in source.entries) {
      mapped[CommonParamKeys.mapKey(entry.key)] = entry.value;
    }

    final query = <String, dynamic>{
      ...mapped,
      NetworkConfig.pathFieldKey: path,
    };
    query[NetworkConfig.signatureFieldKey] = SignatureHelper.generate(
      params: query,
      secret: NetworkConfig.signatureSecret,
    );
    query[NetworkConfig.endpointRandomFieldKey] =
        SignatureHelper.randomDigits();
    query.addAll(queryParameters ?? const <String, dynamic>{});
    query.remove(NetworkConfig.pathFieldKey);
    return query;
  }

  Future<NetworkResponse<dynamic>> _handleResponse(dynamic raw) async {
    final response = _responseParser.parse(raw);

    if (response.code == NetworkConfig.authExpiredCode) {
      await _handleAuthExpired();
      throw BusinessException(response.message, code: response.code);
    }

    if (!response.isSuccess) {
      throw BusinessException(response.message, code: response.code);
    }

    return response;
  }

  Future<void> _handleAuthExpired() async {
    if (_handlingAuthExpired) {
      return;
    }
    _handlingAuthExpired = true;
    try {
      // Placeholder for clearing local auth state and redirecting to login.
      // This must stay centralized and idempotent.
    } finally {
      _handlingAuthExpired = false;
    }
  }
}
