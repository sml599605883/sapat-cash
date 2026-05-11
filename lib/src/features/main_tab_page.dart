import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'auth/login_page.dart';
import 'home/home_page.dart';
import 'home/widgets/home_bottom_nav.dart';
import 'main_tab/main_tab_controller.dart';
import 'mine/mine_page.dart';

class MainTabPage extends StatelessWidget {
  const MainTabPage({super.key});

  Future<void> _handleTabTap(BuildContext context, int index) async {
    if (index == 1 && !context.read<AuthController>().isLoggedIn) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    context.read<MainTabController>().onTabTap(index);
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
