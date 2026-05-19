import 'package:flutter/material.dart';

import '../../../core/layout/screen.dart';

class VerificationHintRow extends StatelessWidget {
  const VerificationHintRow({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/image/verification/chat_hint_icon.png',
          width: screen.dp(38),
          height: screen.dp(38),
        ),
        SizedBox(width: screen.dp(3)),
        Padding(
          padding: EdgeInsets.only(top: screen.dp(25)),
          child: Image.asset(
            'assets/image/verification/top_tip_badge.png',
            width: screen.dp(4),
            height: screen.dp(6),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              screen.dp(16),
              screen.dp(10),
              screen.dp(16),
              screen.dp(10),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E1),
              borderRadius: BorderRadius.circular(screen.dp(14)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              message,
              maxLines: 5,
              style: TextStyle(
                color: const Color(0xFF9A7F65),
                fontSize: screen.dp(12),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
