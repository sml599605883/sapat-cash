import 'package:flutter/material.dart';

import '../../../core/layout/screen.dart';
import '../home_models.dart';

class HomeTopSection extends StatelessWidget {
  const HomeTopSection({super.key, this.section, this.icon});

  static const _lightText = Color(0xFFFFC7AF);
  static const _darkText = Color(0xFF331707);

  final HomeSection? section;
  final HomeIconEntry? icon;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final card = section?.items.isNotEmpty == true
        ? section?.items.first
        : null;
    final hasAuthProgress = card?.authProgress.isNotEmpty == true;
    final slogan = card?.description?.trim();

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
          const SafeArea(bottom: false, child: SizedBox()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
            child: const _WelcomeHeader(),
          ),
          SizedBox(height: screen.dp(18)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
            child: _TopCard(card: card, icon: icon),
          ),
          if (hasAuthProgress)
            Transform.translate(
              offset: Offset(0, -screen.dp(24)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
                child: _UnlockedLimitCard(
                  card: card!,
                  lineImageAsset:
                      'assets/image/home/home_progress_connector.png',
                ),
              ),
            ),
          Container(
            width: double.infinity,
            height: screen.dp(66),
            padding: EdgeInsets.symmetric(vertical: screen.dp(16)),
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/image/home/home_card_top_strip.png'),
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
              ),
            ),
            child: Text(
              slogan ?? '',
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

class _TopCard extends StatelessWidget {
  const _TopCard({required this.card, required this.icon});

  final HomeSectionItem? card;
  final HomeIconEntry? icon;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final appName = card?.productName?.trim();
    final loanTerm = card?.loanTerm?.trim();
    final loanTermText = card?.loanTermText?.trim();
    final interestRate = card?.interestRate?.trim();
    final interestRateText = card?.interestRateText?.trim();
    final amountText = card?.amountText?.trim();
    final amount = card?.amount?.trim();
    final applyText = card?.buttonText?.trim();
    final iconUrl = icon?.imageUrl.trim();
    final hasIconUrl = iconUrl != null && iconUrl.isNotEmpty;
    final hasAuthProgress = card?.authProgress.isNotEmpty == true;
    final cardBottomPadding = hasAuthProgress ? 24.0 : 0.0;

    return Container(
      padding: EdgeInsets.only(bottom: screen.dp(cardBottomPadding)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: screen.dp(275)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(screen.dp(14)),
              image: const DecorationImage(
                image: AssetImage(
                  'assets/image/home/home_gradient_background.png',
                ),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: screen.dp(24)),
              child: Column(
                children: [
                  SizedBox(height: screen.dp(12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(screen.dp(8)),
                        child: SizedBox(
                          width: screen.dp(28),
                          height: screen.dp(28),
                          child: hasIconUrl
                              ? Image.network(
                                  iconUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackIcon(screen),
                                )
                              : _buildFallbackIcon(screen),
                        ),
                      ),
                      SizedBox(width: screen.dp(10)),
                      Text(
                        appName?.isNotEmpty == true ? appName! : 'App Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screen.dp(14),
                          height: 16 / 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (hasAuthProgress) ...[
                    SizedBox(height: screen.dp(18)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screen.dp(12)),
                      child: const Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white,
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: screen.dp(40)),
                  ],
                  SizedBox(height: screen.dp(hasAuthProgress ? 24 : 0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MetricItem(
                        icon: 'assets/image/home/home_calendar_icon.png',
                        value: loanTerm?.isNotEmpty == true
                            ? loanTerm!
                            : '180 Days',
                        label: loanTermText?.isNotEmpty == true
                            ? loanTermText!
                            : 'Loan terms',
                      ),
                      SizedBox(width: screen.dp(68)),
                      _MetricItem(
                        icon: 'assets/image/home/home_percent_icon.png',
                        value: interestRate?.isNotEmpty == true
                            ? interestRate!
                            : '≤0.5% / Day',
                        label: interestRateText?.isNotEmpty == true
                            ? interestRateText!
                            : 'Interest rate',
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
                              amountText?.isNotEmpty == true
                                  ? amountText!
                                  : 'Available up to',
                              style: TextStyle(
                                color: HomeTopSection._lightText,
                                fontSize: screen.dp(14),
                                height: 18 / 14,
                              ),
                            ),
                            SizedBox(height: screen.dp(3)),
                            Text(
                              amount?.isNotEmpty == true ? amount! : '₱60,000',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screen.dp(36),
                                height: 44 / 36,
                                fontFamily: 'Helvetica',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ApplyButton(text: applyText),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(ScreenData screen) {
    return Container(
      width: screen.dp(28),
      height: screen.dp(28),
      decoration: BoxDecoration(
        color: const Color(0xFFD8D8D8),
        borderRadius: BorderRadius.circular(screen.dp(8)),
        border: Border.all(color: const Color(0xFF979797), width: screen.dp(1)),
      ),
    );
  }
}

class _UnlockedLimitCard extends StatelessWidget {
  const _UnlockedLimitCard({required this.card, required this.lineImageAsset});

  final HomeSectionItem card;
  final String lineImageAsset;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final items = card.authProgress;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: screen.dp(24)),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: screen.dp(-70),
            child: Image.asset(
              lineImageAsset,
              width: screen.dp(319),
              height: screen.dp(68),
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              constraints: BoxConstraints(minHeight: screen.dp(94)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screen.dp(14)),
                border: Border.all(
                  color: HomeTopSection._darkText,
                  width: screen.dp(2),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                screen.dp(14),
                screen.dp(8),
                screen.dp(14),
                screen.dp(14),
              ),
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: HomeTopSection._darkText,
                        fontSize: screen.dp(14),
                        height: 16 / 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: const [
                        TextSpan(text: 'My unlocked limit('),
                        TextSpan(
                          text: '₱',
                          style: TextStyle(fontFamily: 'Helvetica'),
                        ),
                        TextSpan(text: ')'),
                      ],
                    ),
                  ),
                  SizedBox(height: screen.dp(16)),
                  Wrap(
                    spacing: screen.dp(8),
                    runSpacing: screen.dp(8),
                    children: items
                        .map(
                          (item) => SizedBox(
                            width: _tagWidth(screen, items.length),
                            child: _UnlockedLimitTag(item: item),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _tagWidth(ScreenData screen, int count) {
    final maxRowCount = count > 4 ? 4 : (count <= 0 ? 1 : count);
    final totalSpacing = screen.dp((maxRowCount - 1) * 8);
    final contentWidth = screen.dp(343 - 28);
    return (contentWidth - totalSpacing) / maxRowCount;
  }
}

class _UnlockedLimitTag extends StatelessWidget {
  const _UnlockedLimitTag({required this.item});

  final HomeProgressEntry item;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final isFinished = item.finished;
    return Container(
      height: screen.dp(36),
      decoration: BoxDecoration(
        color: isFinished ? const Color(0xFFA34B00) : const Color(0xFFE0DDDA),
        borderRadius: BorderRadius.circular(screen.dp(18)),
      ),
      alignment: Alignment.center,
      child: Text(
        item.amount,
        style: TextStyle(
          color: isFinished ? Colors.white : const Color(0xFF908E8C),
          fontSize: screen.dp(16),
          height: 20 / 16,
          fontWeight: isFinished ? FontWeight.w500 : FontWeight.w400,
        ),
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
            color: HomeTopSection._darkText,
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
            color: HomeTopSection._lightText,
            fontSize: screen.dp(10),
          ),
        ),
      ],
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({this.text});

  final String? text;

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
            text?.isNotEmpty == true ? text! : 'Apply Now',
            style: TextStyle(
              color: HomeTopSection._darkText,
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
