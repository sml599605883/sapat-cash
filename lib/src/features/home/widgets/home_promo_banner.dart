import 'package:flutter/material.dart';

import '../../../core/layout/screen.dart';

class HomePromoBanner extends StatelessWidget {
  const HomePromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Container(
      width: screen.dp(343),
      height: screen.dp(120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screen.dp(14)),
      ),
      child: Image.network(
        '',
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/image/home/home_banner_promo.png'),
      ),
    );
  }
}
