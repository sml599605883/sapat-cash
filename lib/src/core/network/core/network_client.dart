import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/network_config.dart';

class NetworkClient {
  NetworkClient({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  Dio get rawDio => _dio;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        connectTimeout: NetworkConfig.connectTimeout,
        receiveTimeout: NetworkConfig.receiveTimeout,
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (_) => true,
      ),
    );
  }

  void clearProxy() {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient(),
    );
  }

  void configureProxy({
    required String host,
    required int port,
    bool allowBadCertificates = false,
  }) {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient()..findProxy = (_) => 'PROXY $host:$port';
        client.badCertificateCallback = (_, hostName, hostPort) {
          return allowBadCertificates;
        };
        return client;
      },
    );
  }
}
