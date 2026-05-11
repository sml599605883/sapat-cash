import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/login_page.dart';
import '../../features/main_tab/main_tab_controller.dart';
import '../../features/mine/account_page.dart';

final class AppPush {
  const AppPush._();

  static Future<T?> push<T>(BuildContext context, {required Widget page}) {
    return pushWithNavigator<T>(Navigator.of(context), page: page);
  }

  static Future<T?> pushWithNavigator<T>(
    NavigatorState navigator, {
    required Widget page,
  }) {
    return navigator.push<T>(_buildPushRoute(page));
  }

  static Future<T?> pushLogin<T>(BuildContext context) {
    return pushLoginWithNavigator<T>(Navigator.of(context));
  }

  static Future<T?> pushLoginWithNavigator<T>(NavigatorState navigator) {
    return navigator.push<T>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  static Future<T?> pushAccount<T>(BuildContext context) {
    return push<T>(context, page: const AccountPage());
  }

  static Future<T?> pushAccountWithNavigator<T>(NavigatorState navigator) {
    return pushWithNavigator<T>(navigator, page: const AccountPage());
  }

  static void popToHomeTabbar(BuildContext context, {bool refreshHome = true}) {
    context.read<MainTabController>().switchToHome(refresh: refreshHome);
    Navigator.of(
      context,
    ).popUntil((route) => route.settings.name == Navigator.defaultRouteName);
  }

  static PageRoute<T> _buildPushRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final primaryPosition = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
        final secondaryPosition =
            Tween<Offset>(begin: Offset.zero, end: const Offset(-0.18, 0))
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(secondaryAnimation);

        return SlideTransition(
          position: primaryPosition,
          child: SlideTransition(position: secondaryPosition, child: child),
        );
      },
    );
  }
}
