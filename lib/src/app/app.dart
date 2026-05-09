import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../features/main_tab_page.dart';
import 'theme/app_theme.dart';

class SapatCashApp extends StatelessWidget {
  const SapatCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sapat Cash',
      theme: buildAppTheme(),
      home: const MainTabPage(),
      builder: EasyLoading.init(),
    );
  }
}
