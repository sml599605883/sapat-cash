import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/layout/screen.dart';
import '../../core/network/api/api_client.dart';
import '../../core/network/core/error_message_adapter.dart';
import '../../core/push/app_push.dart';
import '../../core/push/route_names.dart';
import '../auth/auth_controller.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  static const routeName = RouteNames.account;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const double _dialogDesignWidth = 319;
  static const double _dialogHeroDesignWidth = 122;
  static const double _dialogHeroDesignHeight = 92;

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() {
      _appVersion = 'V${packageInfo.version}';
    });
  }

  Future<void> _handleLogout() async {
    final authController = context.read<AuthController>();
    final confirmed = await _showActionDialog(
      title: 'Leaving already?',
      message:
          'You can come back anytime, but you might miss important updates',
      leftActionText: 'Exit',
      rightActionText: 'Stay',
      leftActionColor: const Color(0xFF908E8C),
      rightActionColor: const Color(0xFFF45834),
      rightActionWeight: FontWeight.w500,
      contentHeight: 40,
      actionTopSpacing: 59,
    );
    if (confirmed != true || !mounted) {
      return;
    }
    EasyLoading.show();
    try {
      await apiService.logout();
      await authController.logout();
      if (!mounted) {
        return;
      }
      AppPush.popToHomeTabbar(context);
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _handleDeleteAccount() async {
    final authController = context.read<AuthController>();
    final confirmed = await _showActionDialog(
      title: 'Before you continue',
      message:
          'Deleting your account will remove all your data and loan records. This action cannot be undone',
      leftActionText: 'Delete Account',
      rightActionText: 'Cancel',
      leftActionColor: const Color(0xFF908E8C),
      rightActionColor: const Color(0xFFF45834),
      rightActionWeight: FontWeight.w500,
      contentHeight: 60,
      actionTopSpacing: 39,
    );
    if (confirmed != true) {
      return;
    }
    EasyLoading.show();
    try {
      await apiService.deleteAccount();
      await authController.logout();
      if (!mounted) {
        return;
      }
      AppPush.popToHomeTabbar(context);
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<bool?> _showActionDialog({
    required String title,
    required String message,
    required String leftActionText,
    required String rightActionText,
    required Color leftActionColor,
    required Color rightActionColor,
    required FontWeight rightActionWeight,
    required double contentHeight,
    required double actionTopSpacing,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.55),
      builder: (dialogContext) {
        final screen = dialogContext.screen;
        final dialogWidth = screen.width - screen.dp(56);
        final dialogContentWidth = dialogWidth - screen.dp(47);
        final heroWidth =
            dialogWidth * (_dialogHeroDesignWidth / _dialogDesignWidth);
        final heroHeight =
            heroWidth * (_dialogHeroDesignHeight / _dialogHeroDesignWidth);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: screen.dp(28)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screen.dp(14)),
          ),
          child: Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screen.dp(14)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: screen.dp(16),
                    bottom: screen.dp(4),
                  ),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color.fromRGBO(255, 244, 225, 0.2),
                        Color.fromRGBO(227, 140, 34, 0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/image/mine/account_dialog_hero.png',
                      width: heroWidth,
                      height: heroHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: screen.dp(30)),
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF281001),
                    fontSize: screen.dp(18),
                    fontWeight: FontWeight.w500,
                    height: 22 / 18,
                  ),
                ),
                SizedBox(height: screen.dp(16)),
                SizedBox(
                  width: dialogContentWidth,
                  height: screen.dp(contentHeight),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF5F5752),
                      fontSize: screen.dp(16),
                      height: 20 / 16,
                    ),
                  ),
                ),
                SizedBox(height: screen.dp(actionTopSpacing)),
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
                SizedBox(
                  height: screen.dp(56),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(true),
                          child: Center(
                            child: Text(
                              leftActionText,
                              style: TextStyle(
                                color: leftActionColor,
                                fontSize: screen.dp(18),
                                height: 22 / 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Color(0xFFE5E5E5)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(false),
                          child: Center(
                            child: Text(
                              rightActionText,
                              style: TextStyle(
                                color: rightActionColor,
                                fontSize: screen.dp(18),
                                fontWeight: rightActionWeight,
                                height: 22 / 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screen.dp(16),
            screen.dp(15),
            screen.dp(14),
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: screen.dp(24),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Image.asset(
                          'assets/image/login_back_icon.png',
                          width: screen.dp(24),
                          height: screen.dp(24),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Account',
                        style: TextStyle(
                          color: Color(0xFF281001),
                          fontSize: screen.dp(20),
                          fontWeight: FontWeight.w500,
                          height: 24 / 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screen.dp(33)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  screen.dp(26),
                  screen.dp(26),
                  screen.dp(125),
                  screen.dp(26),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F3),
                  borderRadius: BorderRadius.circular(screen.dp(14)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: screen.dp(64),
                      height: screen.dp(64),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.circular(screen.dp(10)),
                        border: Border.all(color: const Color(0xFF979797)),
                      ),
                    ),
                    SizedBox(width: screen.dp(32)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Name',
                          style: TextStyle(
                            color: Color(0xFF281001),
                            fontSize: screen.dp(24),
                            fontWeight: FontWeight.w500,
                            height: 28 / 24,
                          ),
                        ),
                        SizedBox(height: screen.dp(10)),
                        Text(
                          _appVersion,
                          style: TextStyle(
                            color: Color(0xFF908E8C),
                            fontSize: screen.dp(16),
                            height: 20 / 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: screen.dp(26)),
              Text(
                'Website',
                style: TextStyle(
                  color: Color(0xFF5F5752),
                  fontSize: screen.dp(16),
                  height: 20 / 16,
                ),
              ),
              SizedBox(height: screen.dp(10)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  screen.dp(16),
                  screen.dp(16),
                  screen.dp(16),
                  screen.dp(16),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F3),
                  borderRadius: BorderRadius.circular(screen.dp(10)),
                ),
                child: Text(
                  'Pera Agad.com.cn',
                  style: TextStyle(
                    color: Color(0xFF281001),
                    fontSize: screen.dp(16),
                    height: 20 / 16,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(height: screen.dp(369)),
              Padding(
                padding: EdgeInsets.only(bottom: screen.dp(34)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleDeleteAccount,
                        child: Container(
                          height: screen.dp(48),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB8B2),
                            borderRadius: BorderRadius.circular(screen.dp(24)),
                          ),
                          child: Text(
                            'Delete Account',
                            style: TextStyle(
                              color: Color(0xFFF45834),
                              fontSize: screen.dp(16),
                              height: 20 / 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screen.dp(28)),
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleLogout,
                        child: Container(
                          height: screen.dp(48),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA3A09B),
                            borderRadius: BorderRadius.circular(screen.dp(24)),
                          ),
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screen.dp(16),
                              height: 20 / 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
