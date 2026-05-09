import 'package:flutter/material.dart';

import '../../../core/layout/screen.dart';

class HomeTopSection extends StatelessWidget {
  const HomeTopSection({super.key});

  static const _lightText = Color(0xFFFFC7AF);

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFAB8AC), Color(0xFFFDDFC5), Color(0xFFFFFFFF)],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Column(
        children: [
          SafeArea(bottom: false, child: SizedBox()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
            child: const _WelcomeHeader(),
          ),
          SizedBox(height: screen.dp(18)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
            child: Container(
              width: double.infinity,
              height: screen.dp(275),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screen.dp(14)),
                image: const DecorationImage(
                  image: AssetImage(
                    'assets/image/home/home_gradient_background.png',
                  ),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: screen.dp(12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: screen.dp(28),
                        height: screen.dp(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8D8D8),
                          borderRadius: BorderRadius.circular(screen.dp(8)),
                          border: Border.all(
                            color: const Color(0xFF979797),
                            width: screen.dp(1),
                          ),
                        ),
                      ),
                      SizedBox(width: screen.dp(10)),
                      Text(
                        'App Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screen.dp(14),
                          height: 16 / 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screen.dp(40)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MetricItem(
                        icon: 'assets/image/home/home_calendar_icon.png',
                        value: '180 Days',
                        label: 'Loan terms',
                      ),
                      SizedBox(width: screen.dp(68)),
                      _MetricItem(
                        icon: 'assets/image/home/home_percent_icon.png',
                        value: '≤0.5% / Day',
                        label: 'Interest rate',
                      ),
                    ],
                  ),
                  SizedBox(height: screen.dp(36)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: screen.dp(31)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available up to',
                              style: TextStyle(
                                color: _lightText,
                                fontSize: screen.dp(14),
                                height: 18 / 14,
                              ),
                            ),
                            SizedBox(height: screen.dp(3)),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '₱',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screen.dp(36),
                                      height: 44 / 36,
                                      fontFamily: 'Helvetica',
                                    ),
                                  ),
                                  TextSpan(
                                    text: '60,000',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screen.dp(36),
                                      height: 44 / 36,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _ApplyButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: screen.dp(66),
            padding: EdgeInsets.symmetric(vertical: screen.dp(16)),
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/image/home/home_card_top_strip.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Text(
              'Your Loan, Apply Now, Get Instantly Approved.',
              style: TextStyle(
                color: const Color(0xFF9A7F65),
                fontSize: screen.dp(12),
                height: 16 / 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Row(
      children: [
        Image.asset(
          'assets/image/home/home_divider_lines.png',
          width: screen.dp(20),
          height: screen.dp(16),
          fit: BoxFit.fill,
        ),
        const Spacer(),
        Text(
          'Wellcom Back',
          style: TextStyle(
            color: _HomeTopSectionState.darkText,
            fontSize: screen.dp(18),
            height: 20 / 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Column(
      children: [
        Image.asset(icon, width: screen.dp(26), height: screen.dp(26)),
        SizedBox(height: screen.dp(6)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: screen.dp(16),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screen.dp(1)),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFFFFC7AF),
            fontSize: screen.dp(10),
          ),
        ),
      ],
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton();

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(screen.dp(30)),
          bottomLeft: Radius.circular(screen.dp(30)),
        ),
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFFFDFBF9), Color(0xFFF7DAC9)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        screen.dp(22),
        screen.dp(12),
        screen.dp(8),
        screen.dp(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Apply Now',
            style: TextStyle(
              color: const Color(0xFF331707),
              fontSize: screen.dp(14),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: screen.dp(13)),
          Image.asset(
            'assets/image/home/home_arrow_right.png',
            width: screen.dp(22),
            height: screen.dp(22),
          ),
        ],
      ),
    );
  }
}

class _HomeTopSectionState {
  static const darkText = Color(0xFF331707);
}
