import 'dart:io';

import '../../report/report_native_bridge.dart';
import '../api/api_client.dart';

class NetworkProxyManager {
  NetworkProxyManager._();

  static Future<void> syncFromSystemProxy() async {
    if (!Platform.isIOS) {
      return;
    }

    final proxy = await ReportNativeBridge.getSystemProxy();
    if (proxy == null || !proxy.isEnabled) {
      ApiClient.clearProxy();
      return;
    }

    ApiClient.configureProxy(
      host: proxy.host,
      port: proxy.port,
      allowBadCertificates: true,
    );
  }
}

class SystemProxyConfig {
  const SystemProxyConfig({
    required this.host,
    required this.port,
    required this.isEnabled,
  });

  final String host;
  final int port;
  final bool isEnabled;
}
