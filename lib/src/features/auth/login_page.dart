import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:sapat_cash/src/core/report/report_manager.dart';

import '../../core/layout/screen.dart';
import '../../core/network/core/error_message_adapter.dart';
import '../../core/push/app_push.dart';
import '../../core/push/route_names.dart';
import '../../core/widgets/dismiss_keyboard.dart';
import 'auth_controller.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const routeName = RouteNames.login;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(context.read<AuthController>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  late final TextEditingController _phoneController;
  late final TextEditingController _codeController;
  late final FocusNode _phoneFocusNode;
  late final FocusNode _codeFocusNode;
  late int _loginStartTimeSeconds;

  @override
  void initState() {
    super.initState();
    _loginStartTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final savedPhone = context.read<AuthController>().phone;
    final displayPhone = savedPhone.startsWith('+63')
        ? savedPhone.substring(3)
        : savedPhone;
    _phoneController = TextEditingController(text: displayPhone);
    _codeController = TextEditingController();
    _codeController.addListener(_handleCodeChanged);
    _phoneFocusNode = FocusNode();
    _codeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.removeListener(_handleCodeChanged);
    _codeController.dispose();
    _phoneFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _backToHome() {
    AppPush.popToHomeTabbar(context);
  }

  void _handleCodeChanged() {
    final controller = context.read<LoginController>();
    final code = _codeController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (code.length == 6 && !controller.submitting) {
      _handleSubmit();
    }
  }

  Future<void> _handleRequestCode() async {
    final controller = context.read<LoginController>();
    final phone = _phoneController.text;
    try {
      _loginStartTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await controller.requestSmsCode(phone);
      if (!mounted) {
        return;
      }
      _codeFocusNode.requestFocus();
      EasyLoading.dismiss();
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    }
  }

  Future<void> _handleSubmit() async {
    final controller = context.read<LoginController>();
    final phone = _phoneController.text;
    final code = _codeController.text;
    FocusScope.of(context).unfocus();
    EasyLoading.show();
    try {
      await controller.login(phone: phone, code: code);
      await ReportManager.instance.onLoginSuccess();
      ReportManager.instance.reportRiskBehavior(
        productId: '',
        sceneType: '1',
        orderNo: '',
        startTimeSeconds: _loginStartTimeSeconds,
      );
      if (!mounted) {
        return;
      }
      _backToHome();
    } catch (error) {
      _codeController.clear();
      _codeFocusNode.requestFocus();
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final controller = context.watch<LoginController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: DismissKeyboard(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              screen.dp(16),
              screen.dp(15),
              screen.dp(16),
              screen.dp(32),
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
                          onTap: _backToHome,
                          child: Image.asset(
                            'assets/image/login_back_icon.png',
                            width: screen.dp(24),
                            height: screen.dp(24),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: const Color(0xFF331707),
                            fontSize: screen.dp(18),
                            fontWeight: FontWeight.w800,
                            height: screen.dp(20) / screen.dp(18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screen.dp(56)),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screen.dp(14)),
                    child: Image.asset(
                      'assets/image/logo.png',
                      width: screen.dp(92),
                      height: screen.dp(92),
                    ),
                  ),
                ),
                SizedBox(height: screen.dp(26)),
                Center(
                  child: Text(
                    'SAPAT CASH',
                    style: TextStyle(
                      color: const Color(0xFF281001),
                      fontSize: screen.dp(20),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: screen.dp(32)),
                Text(
                  'Please fill in your phone number',
                  style: TextStyle(
                    color: const Color(0xFF5F5752),
                    fontSize: screen.dp(16),
                  ),
                ),
                SizedBox(height: screen.dp(16)),
                _LoginInputCard(
                  child: Row(
                    children: [
                      Text(
                        '+63',
                        style: TextStyle(
                          color: const Color(0xFF281001),
                          fontSize: screen.dp(16),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: screen.dp(16),
                        color: const Color(0xFFDBD9D7),
                        margin: EdgeInsets.symmetric(horizontal: screen.dp(10)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _codeFocusNode.requestFocus(),
                          style: TextStyle(
                            color: const Color(0xFF281001),
                            fontSize: screen.dp(16),
                            height: screen.dp(20) / screen.dp(16),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Cellphone number',
                            hintStyle: TextStyle(
                              color: const Color(0xFFCACACA),
                              fontSize: screen.dp(14),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screen.dp(26)),
                Text(
                  'Send SMS verification code',
                  style: TextStyle(
                    color: const Color(0xFF5F5752),
                    fontSize: screen.dp(16),
                  ),
                ),
                SizedBox(height: screen.dp(16)),
                _LoginInputCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleSubmit(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: TextStyle(
                            color: const Color(0xFF281001),
                            fontSize: screen.dp(16),
                            height: screen.dp(20) / screen.dp(16),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Verification code',
                            hintStyle: TextStyle(
                              color: const Color(0xFFCACACA),
                              fontSize: screen.dp(14),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.canRequestCode
                            ? _handleRequestCode
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E1),
                            borderRadius: BorderRadius.circular(screen.dp(6)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: screen.dp(25),
                            vertical: screen.dp(6),
                          ),
                          child: Text(
                            controller.countdown > 0
                                ? '${controller.countdown}s'
                                : controller.sendingCode
                                ? '...'
                                : 'Send',
                            style: TextStyle(
                              color: const Color(0xFFF45834),
                              fontSize: screen.dp(14),
                              // height: screen.dp(16) / screen.dp(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screen.dp(14)),
                GestureDetector(
                  onTap: context.read<LoginController>().toggleAgreement,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: screen.dp(2)),
                        child: Image.asset(
                          controller.agreed
                              ? 'assets/image/login/checkbox_checked.png'
                              : 'assets/image/login/checkbox_unchecked.png',
                          width: screen.dp(16),
                          height: screen.dp(16),
                        ),
                      ),
                      SizedBox(width: screen.dp(10)),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: const Color(0xFF331707),
                              fontSize: screen.dp(12),
                            ),
                            children: const [
                              TextSpan(text: 'I have read and agree to the '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(color: Color(0xFFF45834)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screen.dp(26)),
                Center(
                  child: GestureDetector(
                    onTap: controller.submitting ? null : _handleSubmit,
                    child: Container(
                      width: screen.dp(232),
                      height: screen.dp(48),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(screen.dp(24)),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFFF89350), Color(0xFFF45834)],
                        ),
                      ),
                      child: Text(
                        controller.submitting
                            ? 'Loading...'
                            : 'Sign up / Sign in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screen.dp(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginInputCard extends StatelessWidget {
  const _LoginInputCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Container(
      height: screen.dp(52),
      padding: EdgeInsets.symmetric(horizontal: screen.dp(15)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screen.dp(10)),
        border: Border.all(color: const Color(0xFFDBD9D7)),
      ),
      child: child,
    );
  }
}
