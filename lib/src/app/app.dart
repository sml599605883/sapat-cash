import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../core/network/network_status_controller.dart';
import '../core/push/app_push.dart';
import '../features/network/offline_page.dart';
import '../features/main_tab_page.dart';
import 'theme/app_theme.dart';

class SapatCashApp extends StatelessWidget {
  const SapatCashApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  void _configureEasyLoading() {
    EasyLoading.instance
      ..userInteractions = false
      ..dismissOnTap = false
      ..maskType = EasyLoadingMaskType.custom
      ..maskColor = const Color(0x33000000)
      ..indicatorType = EasyLoadingIndicatorType.ring;
  }

  @override
  Widget build(BuildContext context) {
    _configureEasyLoading();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sapat Cash',
      navigatorKey: navigatorKey,
      navigatorObservers: [AppPush.navigatorObserver],
      theme: buildAppTheme(),
      home: const MainTabPage(),
      builder: (context, child) {
        final easyLoadingBuilder = EasyLoading.init();
        final mediaQuery = MediaQuery.of(context);
        final isOffline = context.select<NetworkStatusController, bool>(
          (controller) => controller.isOffline,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Stack(
            children: [
              easyLoadingBuilder(context, child),
              if (isOffline) const Positioned.fill(child: OfflinePage()),
            ],
          ),
        );
      },
    );
  }
}
