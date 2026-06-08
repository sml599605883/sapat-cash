import 'package:flutter/material.dart';

import '../../core/layout/screen.dart';

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screen.dp(166)),
            Image.asset(
              'assets/image/net_bg.png',
              width: screen.dp(287),
              fit: BoxFit.contain,
            ),
            SizedBox(height: screen.dp(26)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screen.dp(36)),
              child: Text(
                'No internet. Pull to refresh or check settings.',
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
    );
  }
}
