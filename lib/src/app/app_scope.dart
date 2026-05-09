import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../features/auth/auth_controller.dart';
import '../features/main_tab/main_tab_controller.dart';

class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()..initialize()),
        ChangeNotifierProvider(create: (_) => MainTabController()),
      ],
      child: child,
    );
  }
}
