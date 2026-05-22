import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/layout/screen.dart';
import '../../core/push/app_push.dart';
import '../../core/push/route_names.dart';
import 'recredit_task_coordinator.dart';

class WaitingCreditPage extends StatefulWidget {
  const WaitingCreditPage({super.key, required this.productId});

  static const routeName = RouteNames.waitingCredit;

  final String productId;

  @override
  State<WaitingCreditPage> createState() => _WaitingCreditPageState();
}

class _WaitingCreditPageState extends State<WaitingCreditPage> {
  static const Duration _progressDuration = Duration(seconds: 35);
  static const Duration _progressTick = Duration(milliseconds: 100);

  Timer? _progressTimer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    RecreditTaskCoordinator.instance.start(productId: widget.productId);
    _progressTimer = Timer.periodic(_progressTick, (_) {
      if (!mounted) {
        return;
      }
      final nextProgress =
          _progress +
          _progressTick.inMilliseconds / _progressDuration.inMilliseconds;
      setState(() {
        _progress = nextProgress.clamp(0.0, 1.0);
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screen.dp(15)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
              child: SizedBox(
                height: screen.dp(24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => AppPush.pop(context),
                    child: Image.asset(
                      'assets/image/login_back_icon.png',
                      width: screen.dp(24),
                      height: screen.dp(24),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: screen.dp(166)),
                  Image.asset(
                    'assets/image/pic_bg.png',
                    width: screen.dp(287),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: screen.dp(27)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screen.dp(0)),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          width: double.infinity,
                          height: screen.dp(6),
                          color: const Color(0xFFE7E7E7),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: constraints.maxWidth * _progress,
                            height: screen.dp(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFB440),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(screen.dp(100)),
                                bottomRight: Radius.circular(screen.dp(100)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: screen.dp(26)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screen.dp(36)),
                    child: Text(
                      'Calculating your credit limit, just 30 seconds\nPlease wait patiently',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF5F5752),
                        fontSize: screen.dp(14),
                        height: 18 / 14,
                        fontWeight: FontWeight.w400,
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
  }
}
