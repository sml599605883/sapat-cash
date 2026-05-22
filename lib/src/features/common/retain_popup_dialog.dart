import 'package:flutter/material.dart';

import '../../core/layout/screen.dart';

class RetainPopupDialog extends StatelessWidget {
  const RetainPopupDialog({
    super.key,
    required this.imageUrl,
    required this.onGoBack,
    required this.onGetFunds,
  });

  final String imageUrl;
  final VoidCallback onGoBack;
  final VoidCallback onGetFunds;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final dialogWidth = screen.width - screen.dp(50);
    final dialogHeight = dialogWidth * (322 / 325);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(screen.dp(20)),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                left: screen.dp(32),
                right: screen.dp(32),
                bottom: screen.dp(36),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(label: 'Go Back', onTap: onGoBack),
                    ),
                    SizedBox(width: screen.dp(11)),
                    Expanded(
                      child: _ActionButton(
                        label: 'Get Funds',
                        onTap: onGetFunds,
                        bgColors: [Color(0xFFF89350), Color(0xFFF45834)],
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.bgColors = const [Color(0xFFA3A09B), Color(0xFFA3A09B)],
  });

  final String label;
  final VoidCallback onTap;
  final List<Color> bgColors;
  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(screen.dp(10)),
        ),
        height: screen.dp(36),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: screen.dp(16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
