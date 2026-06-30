import 'package:flutter/material.dart';
import 'package:sapat_cash/src/core/network/config/network_config.dart';
import 'package:sapat_cash/src/core/push/app_push.dart';

import '../../../core/layout/screen.dart';
import '../home_models.dart';

class HomeTopSection extends StatelessWidget {
  const HomeTopSection({super.key, this.section, this.icon});

  static const _lightText = Color(0xFFFFC7AF);
  static const _darkText = Color(0xFF331707);

  final HomeLargeCardItem? section;
  final HomeIconEntry? icon;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final card = section;
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
      child: GestureDetector(
        onTap: () =>
            AppPush.clickApply(context, productId: card?.productId ?? ''),
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
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: screen.dp(16)),
              constraints: hasAuthProgress
                  ? null
                  : BoxConstraints(minHeight: screen.dp(66)),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/image/home/home_card_top_strip.png',
                  ),
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    alignment: Alignment.center,
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
                  if (hasAuthProgress)
                    Padding(
                      padding: EdgeInsets.only(
                        left: screen.dp(16),
                        right: screen.dp(16),
                        bottom: screen.dp(24),
                        top: screen.dp(7),
                      ),
                      child: _UnlockedLimitCard(card: card!),
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

class _TopCard extends StatelessWidget {
  const _TopCard({required this.card, required this.icon});

  final HomeLargeCardItem? card;
  final HomeIconEntry? icon;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final appName = card?.productName?.trim();
    final amountText = card?.amountText?.trim();
    final amount = card?.amount?.trim();
    final applyText = card?.buttonText?.trim();
    final productLogo = card?.productLogo?.trim() ?? '';
    final hasIconUrl = productLogo.isNotEmpty;
    final creditProgress =
        card?.creditProgress ?? const <HomeCreditProgressEntry>[];

    return Column(
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
                              productLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackIcon(screen),
                            )
                          : _buildFallbackIcon(screen),
                    ),
                  ),
                  SizedBox(width: screen.dp(10)),
                  Text(
                    appName ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screen.dp(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screen.dp(40)),
              SizedBox(
                height: screen.dp(66),
                child: creditProgress.isNotEmpty
                    ? _CreditProgressRow(items: creditProgress)
                    : _LoanMetricsRow(card: card),
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
                          amountText ?? '',
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
      ],
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

class _LoanMetricsRow extends StatelessWidget {
  const _LoanMetricsRow({required this.card});

  final HomeLargeCardItem? card;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final loanTerm = card?.loanTerm?.trim() ?? '';
    final loanTermText = card?.loanTermText?.trim() ?? '';
    final interestRate = card?.interestRate?.trim() ?? '';
    final interestRateText = card?.interestRateText?.trim() ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MetricItem(
          icon: 'assets/image/home/home_calendar_icon.png',
          value: loanTerm,
          label: loanTermText,
        ),
        SizedBox(width: screen.dp(68)),
        _MetricItem(
          icon: 'assets/image/home/home_percent_icon.png',
          value: interestRate,
          label: interestRateText,
        ),
      ],
    );
  }
}

class _CreditProgressRow extends StatelessWidget {
  const _CreditProgressRow({required this.items});

  final List<HomeCreditProgressEntry> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.length == 1 ? items : [items.first, items.last];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: visibleItems
          .map((item) => _CreditProgressItem(item: item))
          .toList(),
    );
  }
}

class _CreditProgressItem extends StatelessWidget {
  const _CreditProgressItem({required this.item});

  final HomeCreditProgressEntry item;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: screen.dp(26),
          height: screen.dp(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFAB8AC), Color(0xFFFDDFC5), Color(0xFFFFF2DD)],
              stops: [0, 0.45, 0.98],
            ),
            borderRadius: BorderRadius.circular(screen.dp(6)),
          ),
          alignment: Alignment.center,
          child: Text(
            item.period,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HomeTopSection._darkText,
              fontSize: screen.dp(18),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: screen.dp(6)),
        Text(
          item.periodText,
          style: TextStyle(
            color: Colors.white,
            fontSize: screen.dp(16),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          item.interestRate,
          style: TextStyle(
            color: HomeTopSection._lightText,
            fontSize: screen.dp(10),
          ),
        ),
      ],
    );
  }
}

class _UnlockedLimitCard extends StatelessWidget {
  const _UnlockedLimitCard({required this.card});

  static const double _cardDesignWidth = 343;
  static const double _lineDesignWidth = 319;
  static const double _lineDesignHeight = 68;

  final HomeLargeCardItem card;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final items = card.authProgress;
    final cardWidth = screen.width - screen.dp(84);
    final lineWidth = cardWidth * (_lineDesignWidth / _cardDesignWidth);
    final lineHeight = lineWidth * (_lineDesignHeight / _lineDesignWidth);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: screen.dp(24)),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  spacing: screen.dp(7),
                  children: items
                      .map(
                        (item) =>
                            Expanded(child: _UnlockedLimitTag(item: item)),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Positioned(
            top: screen.dp(-48),
            child: Image.asset(
              'assets/image/home/home_progress_connector.png',
              width: lineWidth,
              height: lineHeight,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
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
        GestureDetector(
          onTap: () => AppPush.pushWebView(
            context,
            url: '${NetworkConfig.defaultWebBaseUrl}/#/OsteotomesLensless',
          ),
          child: Image.asset(
            'assets/image/home/home_divider_lines.png',
            width: screen.dp(20),
            height: screen.dp(20),
            fit: BoxFit.fill,
          ),
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
            text ?? '',
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
