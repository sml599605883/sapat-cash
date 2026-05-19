import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/push/app_push.dart';
import 'auth/auth_controller.dart';
import '../core/push/route_names.dart';
import 'home/home_page.dart';
import 'home/widgets/home_bottom_nav.dart';
import 'main_tab/main_tab_controller.dart';
import 'mine/mine_page.dart';

class MainTabPage extends StatelessWidget {
  const MainTabPage({super.key});

  static const routeName = RouteNames.mainTab;

  Future<void> _handleTabTap(BuildContext context, int index) async {
    final authController = context.read<AuthController>();
    final mainTabController = context.read<MainTabController>();
    final navigator = Navigator.of(context);
    await authController.ensureInitialized();
    if (index == 1 && !authController.isLoggedIn) {
      await AppPush.pushLoginWithNavigator(navigator);
      return;
    }
    if (!context.mounted) {
      return;
    }
    mainTabController.onTabTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MainTabController>();

    return Scaffold(
      body: IndexedStack(
        index: controller.currentIndex,
        children: [const HomePage(), const MinePage()],
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: controller.currentIndex,
        onTap: (index) => _handleTabTap(context, index),
      ),
    );
  }
}
