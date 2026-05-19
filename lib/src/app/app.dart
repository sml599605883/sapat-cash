import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../core/push/app_push.dart';
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
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: easyLoadingBuilder(context, child),
        );
      },
    );
  }
}
