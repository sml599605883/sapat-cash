import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/layout/screen.dart';
import '../../../core/push/app_push.dart';
import '../home_models.dart';

class HomeRecommendationList extends StatelessWidget {
  const HomeRecommendationList({super.key, this.items = const []});

  final List<HomeProductListItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final screen = context.screen;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        screen.dp(16),
        screen.dp(24),
        screen.dp(16),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/image/mine/mine_badge_dot.png',
                width: screen.dp(16),
                height: screen.dp(16),
              ),
              SizedBox(width: screen.dp(8)),
              Text(
                'Recommendation',
                style: TextStyle(
                  color: _palette(context).homeTitle,
                  fontSize: screen.dp(18),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: screen.dp(16)),
          for (var index = 0; index < items.length; index++) ...[
            _RecommendationCard(item: items[index]),
            if (index != items.length - 1) SizedBox(height: screen.dp(16)),
          ],
        ],
      ),
    );
  }

  static AppPalette _palette(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final HomeProductListItem item;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final palette = HomeRecommendationList._palette(context);
    final productId = item.productId?.trim() ?? '';
    final amountText = item.amountText?.trim() ?? '';
    final amount = item.amount?.trim() ?? '';
    final termLabel = item.loanTermsText?.trim() ?? '';
    final termValue = item.loanTerm?.trim() ?? '';
    final rateLabel = item.interestRateText?.trim() ?? '';
    final rateValue = item.interestRate?.trim() ?? '';
    final disabled = item.isButtonDisabled || productId.isEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled
          ? null
          : () => AppPush.clickApply(context, productId: productId),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          screen.dp(16),
          screen.dp(20),
          screen.dp(16),
          screen.dp(20),
        ),
        decoration: BoxDecoration(
          color: palette.homeCardBackground,
          borderRadius: BorderRadius.circular(screen.dp(14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ProductLogo(imageUrl: item.productLogo),
                SizedBox(width: screen.dp(10)),
                Expanded(
                  child: Text(
                    item.productName?.trim() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.homeTitle,
                      fontSize: screen.dp(14),
                      height: 16 / 14,
                    ),
                  ),
                ),
                SizedBox(width: screen.dp(12)),
                _MetricGroup(value: termValue, label: termLabel),
                SizedBox(width: screen.dp(14)),
                _MetricGroup(value: rateValue, label: rateLabel),
              ],
            ),
            SizedBox(height: screen.dp(10)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            amount,
                            style: TextStyle(
                              color: palette.homeMetricValue,
                              fontSize: screen.dp(24),
                              fontFamily: 'Helvetica',
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: palette.homeMetricValue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screen.dp(8)),
                      Text(
                        amountText,
                        style: TextStyle(
                          color: palette.homeBody,
                          fontSize: screen.dp(14),
                          height: 16 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screen.dp(12)),
                _ActionButton(item: item),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductLogo extends StatelessWidget {
  const _ProductLogo({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final palette = HomeRecommendationList._palette(context);
    final url = imageUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(screen.dp(4)),
      child: SizedBox(
        width: screen.dp(28),
        height: screen.dp(28),
        child: url.isEmpty
            ? _buildFallback(palette, screen)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallback(palette, screen),
              ),
      ),
    );
  }

  Widget _buildFallback(AppPalette palette, ScreenData screen) {
    return Container(
      decoration: BoxDecoration(
        color: palette.homeFallback,
        borderRadius: BorderRadius.circular(screen.dp(4)),
        border: Border.all(
          color: palette.homeFallbackBorder,
          width: screen.dp(1),
        ),
      ),
    );
  }
}

class _MetricGroup extends StatelessWidget {
  const _MetricGroup({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final palette = HomeRecommendationList._palette(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.homeMetricValue,
            fontSize: screen.dp(12),
            height: 16 / 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screen.dp(4)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.homeMetricLabel,
            fontSize: screen.dp(12),
            height: 16 / 12,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.item});

  final HomeProductListItem item;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final palette = HomeRecommendationList._palette(context);
    final isFeatured = item.isButtonDisabled == true;
    final productId = item.productId?.trim() ?? '';
    final disabled = item.isButtonDisabled || productId.isEmpty;
    final buttonText = item.buttonText?.trim().isNotEmpty == true
        ? item.buttonText!.trim()
        : 'Apply now';

    return Opacity(
      opacity: disabled ? 0.72 : 1,
      child: Container(
        width: screen.dp(148),
        height: screen.dp(34),
        decoration: BoxDecoration(
          color: disabled ? palette.homeButtonDisabled : null,
          borderRadius: BorderRadius.circular(screen.dp(18)),
          gradient: LinearGradient(
            colors: isFeatured
                ? [Color(0xFFA3A09B), Color(0xFFA3A09B)]
                : [Color(0xFFF89350), Color(0xFFF45834)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          buttonText,
          style: TextStyle(
            color: Colors.white,
            fontSize: screen.dp(14),
            height: 18 / 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
