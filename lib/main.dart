import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/app/app.dart';
import 'src/app/app_scope.dart';
import 'src/core/network/api/api_client.dart';
import 'src/core/network/debug/network_proxy_manager.dart';
import 'src/core/report/report_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NetworkProxyManager.syncFromSystemProxy();
  await ApiClient.initialize();
  runApp(const AppScope(child: SapatCashApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ReportManager.instance.onAppStarted();
  });
}
