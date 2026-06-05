import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/layout/screen.dart';
import '../../../core/network/api/api_client.dart';
import '../../../core/network/core/error_message_adapter.dart';
import '../../../core/push/app_push.dart';
import '../../verification/pages/bank_account_list_page.dart';
import '../../verification/pages/bind_card_page.dart';
import '../home_models.dart';

enum HomeProgressActionKind { detail, retry, changeAccount }

HomeProgressActionKind resolveHomeProgressActionKind(HomeActionButton button) {
  switch (button.type) {
    case HomeActionType.retry:
      return HomeProgressActionKind.retry;
    case HomeActionType.change:
      return HomeProgressActionKind.changeAccount;
    case HomeActionType.repay:
    case HomeActionType.unknown:
      return HomeProgressActionKind.detail;
  }
}

class HomeProgressModule extends StatefulWidget {
  const HomeProgressModule({super.key, this.items = const []});

  final List<HomeProgressCardItem> items;

  @override
  State<HomeProgressModule> createState() => _HomeProgressModuleState();
}

class _HomeProgressModuleState extends State<HomeProgressModule> {
  static const _interval = Duration(seconds: 3);

  late PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = _buildPageController();
    _syncAutoPlay();
  }

  @override
  void reassemble() {
    super.reassemble();
    final previousPage = _currentPage;
    _pageController.dispose();
    _pageController = _buildPageController(initialPage: previousPage);
  }

  @override
  void didUpdateWidget(covariant HomeProgressModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _syncAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  PageController _buildPageController({int initialPage = 0}) {
    return PageController(initialPage: initialPage);
  }

  void _syncAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.items.length <= 1) {
      return;
    }
    _autoPlayTimer = Timer.periodic(_interval, (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextPage = (_currentPage + 1) % widget.items.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final screen = context.screen;
    final palette = Theme.of(context).extension<AppPalette>()!;

    return Padding(
      padding: EdgeInsets.only(
        top: screen.dp(16),
        left: screen.dp(16),
        right: screen.dp(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: screen.dp(139),
            child: PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (index) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _ProgressCard(item: items[index], palette: palette);
              },
            ),
          ),
          if (items.length > 1) ...[
            SizedBox(height: screen.dp(10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (index) {
                final active = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: screen.dp(active ? 18 : 6),
                  height: screen.dp(6),
                  margin: EdgeInsets.symmetric(horizontal: screen.dp(3)),
                  decoration: BoxDecoration(
                    color: active
                        ? palette.brandPrimary
                        : palette.homeProgressIndicatorInactive,
                    borderRadius: BorderRadius.circular(screen.dp(3)),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.item, required this.palette});

  final HomeProgressCardItem item;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final style = _ProgressCardStyle.resolve(item);
    final buttons = _resolveButtons();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: style.outerBackground,
          borderRadius: BorderRadius.circular(screen.dp(20)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(screen.dp(10), 0, screen.dp(10), 0),
              child: Column(
                children: [
                  _InnerInfoCard(item: item, style: style, palette: palette),
                  SizedBox(height: screen.dp(10)),
                  if (buttons.isNotEmpty)
                    _BottomActions(
                      buttons: buttons,
                      style: style,
                      onTap: (button) => _handleBottomAction(
                        context,
                        button,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _TopRibbon(style: style),
            ),
          ],
        ),
      ),
    );
  }

  List<HomeActionButton> _resolveButtons() {
    final actions = item.buttons
        .where((button) => button.enabled && button.text.trim().isNotEmpty)
        .toList();
    if (actions.isNotEmpty) {
      return actions.take(2).toList();
    }
    switch (_ProgressCardStyle.resolve(item).kind) {
      case _ProgressCardKind.failedSingle:
        return const [
          HomeActionButton(
            type: HomeActionType.change,
            rawType: 'change',
            enabled: true,
            text: 'Change',
          ),
        ];
      case _ProgressCardKind.failedDual:
        return const [
          HomeActionButton(
            type: HomeActionType.retry,
            rawType: 'retry',
            enabled: true,
            text: 'Try Again',
          ),
          HomeActionButton(
            type: HomeActionType.change,
            rawType: 'change',
            enabled: true,
            text: 'Change',
          ),
        ];
      case _ProgressCardKind.releasingFunds:
      case _ProgressCardKind.inReview:
        return const <HomeActionButton>[];
      case _ProgressCardKind.pendingPayment:
      case _ProgressCardKind.pastDue:
        return const [
          HomeActionButton(
            type: HomeActionType.change,
            rawType: 'change',
            enabled: true,
            text: 'Change',
          ),
        ];
    }
  }

  Future<void> _openDetail(BuildContext context) async {
    await _openDetailWithNavigator(Navigator.of(context));
  }

  Future<void> _openDetailWithNavigator(NavigatorState navigator) async {
    final url = item.orderDetailLink.trim();
    if (url.isNotEmpty) {
      await AppPush.openWebUriWithNavigator(navigator, rawUrl: url);
      return;
    }
    final productId = item.productId.trim();
    if (productId.isEmpty || !navigator.mounted) {
      return;
    }
    await AppPush.productDetail(navigator.context, productId: productId);
  }

  Future<void> _handleBottomAction(
    BuildContext context,
    HomeActionButton button,
  ) async {
    switch (resolveHomeProgressActionKind(button)) {
      case HomeProgressActionKind.retry:
        await _handleRetryOrder(context);
      case HomeProgressActionKind.changeAccount:
        await _handleChangeAccount(context);
      case HomeProgressActionKind.detail:
        await _openDetail(context);
    }
  }

  Future<void> _handleRetryOrder(BuildContext context) async {
    final navigator = Navigator.of(context);
    final orderNo = item.loanOrderNo.trim();
    if (orderNo.isEmpty) {
      await _openDetailWithNavigator(navigator);
      return;
    }
    try {
      final response = await apiService.confirmRetryOrder(orderNo: orderNo);
      final claviform = response.json['claviform'].stringValue.trim();
      if (claviform.isEmpty) {
        await _openDetailWithNavigator(navigator);
        return;
      }
      await AppPush.openWebUriWithNavigator(navigator, rawUrl: claviform);
    } catch (error) {
      if (!navigator.mounted) {
        return;
      }
      await _showActionError(error);
    }
  }

  Future<void> _handleChangeAccount(BuildContext context) async {
    final navigator = Navigator.of(context);
    final productId = item.productId.trim();
    final orderNo = item.loanOrderNo.trim();
    if (productId.isEmpty || orderNo.isEmpty) {
      await _openDetailWithNavigator(navigator);
      return;
    }
    try {
      final response = await apiService.fetchAccountList(productId: productId);
      final accountList = response.json['noniron'].listValue;
      await AppPush.pushWithNavigator<void>(
        navigator,
        page: accountList.isNotEmpty
            ? BankAccountListPage(productId: productId, orderNo: orderNo)
            : BindCardPage(
                productId: productId,
                orderNo: orderNo,
                isChangeBankCard: true,
              ),
        routeName: accountList.isNotEmpty
            ? BankAccountListPage.routeName
            : BindCardPage.routeName,
      );
    } catch (error) {
      if (!navigator.mounted) {
        return;
      }
      await _showActionError(error);
    }
  }

  Future<void> _showActionError(Object error) async {
    final message = ErrorMessageAdapter.resolve(error);
    if (message.trim().isEmpty) {
      return;
    }
    EasyLoading.showToast(message);
  }
}

class _TopRibbon extends StatelessWidget {
  const _TopRibbon({required this.style});

  final _ProgressCardStyle style;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Container(
      height: screen.dp(31),
      decoration: BoxDecoration(
        color: style.ribbonColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(screen.dp(20)),
          topRight: Radius.circular(screen.dp(20)),
          bottomLeft: Radius.circular(screen.dp(40)),
          bottomRight: Radius.circular(screen.dp(40)),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: screen.dp(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: screen.dp(24),
            height: screen.dp(24),
            decoration: BoxDecoration(
              boxShadow: style.showWarning
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).extension<AppPalette>()!.homeProgressAlertShadow,
                        blurRadius: screen.dp(8),
                        offset: Offset(0, screen.dp(2)),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Image.asset(style.iconAsset, fit: BoxFit.contain),
          ),
          SizedBox(width: screen.dp(10)),
          Text(
            style.title,
            style: TextStyle(
              color: style.titleColor,
              fontSize: screen.dp(12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InnerInfoCard extends StatelessWidget {
  const _InnerInfoCard({
    required this.item,
    required this.style,
    required this.palette,
  });

  final HomeProgressCardItem item;
  final _ProgressCardStyle style;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Container(
      height: screen.dp(item.isNoButtons ? 125 : 91),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screen.dp(14)),
      ),
      padding: EdgeInsets.only(
        top: screen.dp(28),
        left: screen.dp(14),
        right: screen.dp(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProductLogo(imageUrl: item.productLogo, palette: palette),
              SizedBox(width: screen.dp(10)),
              SizedBox(
                width: screen.dp(60),
                child: Text(
                  item.productName.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: style.valueColor,
                    fontSize: screen.dp(12),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          Spacer(),
          _DividerLine(color: style.dividerColor),
          Spacer(),
          _MetricColumn(
            value: _amountText(),
            label: _amountLabel(),
            style: style,
            width: screen.dp(94),
          ),
          Spacer(),
          _DividerLine(color: style.dividerColor),
          Spacer(),
          _MetricColumn(
            value: _dateText(),
            label: _dateLabel(),
            style: style,
            width: screen.dp(98),
          ),
        ],
      ),
    );
  }

  String _amountText() {
    final amount = item.amount.trim();
    if (amount.isNotEmpty) {
      return amount;
    }
    if (item.loanAmount.isNotEmpty) {
      return item.loanAmount;
    }
    return '--';
  }

  String _amountLabel() {
    final label = item.loanAmountText.trim();
    if (label.isNotEmpty) {
      return label;
    }
    return 'Loan Amount';
  }

  String _dateText() {
    final text = item.applyDate.trim();
    if (text.isNotEmpty) {
      return text;
    }
    return '--';
  }

  String _dateLabel() {
    final label = item.applyDateText.trim();
    if (label.isNotEmpty) {
      return label;
    }
    return 'Loan Date';
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.value,
    required this.label,
    required this.style,
    required this.width,
  });

  final String value;
  final String label;
  final _ProgressCardStyle style;
  final double width;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: style.valueColor,
              fontSize: screen.dp(12),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: screen.dp(7)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: style.labelColor,
              fontSize: screen.dp(12),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Container(width: screen.dp(1), height: screen.dp(28), color: color);
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.buttons,
    required this.style,
    required this.onTap,
  });

  final List<HomeActionButton> buttons;
  final _ProgressCardStyle style;
  final ValueChanged<HomeActionButton> onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    if (buttons.length == 1) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: screen.dp(80)),
        child: Center(
          child: _ActionButton(
            text: buttons.first.text,
            backgroundColor: style.primaryButtonColor,
            textColor: Colors.white,
            onTap: () => onTap(buttons.first),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screen.dp(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _ActionButton(
              text: buttons.first.text,
              backgroundColor: style.secondaryButtonColor,
              textColor: Colors.white,
              onTap: () => onTap(buttons.first),
            ),
          ),
          SizedBox(width: screen.dp(24)),
          Expanded(
            child: _ActionButton(
              text: buttons.last.text,
              backgroundColor: style.primaryButtonColor,
              textColor: Colors.white,
              onTap: () => onTap(buttons.last),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: screen.dp(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(screen.dp(15)),
        ),
        padding: EdgeInsets.symmetric(horizontal: screen.dp(5)),
        child: Center(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: screen.dp(14),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductLogo extends StatelessWidget {
  const _ProductLogo({required this.imageUrl, required this.palette});

  final String imageUrl;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final url = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(screen.dp(4)),
      child: SizedBox(
        width: screen.dp(20),
        height: screen.dp(20),
        child: url.isEmpty
            ? _fallback(screen)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(screen),
              ),
      ),
    );
  }

  Widget _fallback(ScreenData screen) {
    return Container(
      decoration: BoxDecoration(
        color: palette.homeFallback,
        borderRadius: BorderRadius.circular(screen.dp(4)),
        border: Border.all(color: palette.homeFallbackBorder),
      ),
    );
  }
}

enum _ProgressCardKind {
  failedSingle,
  failedDual,
  releasingFunds,
  pendingPayment,
  inReview,
  pastDue,
}

class _ProgressCardStyle {
  const _ProgressCardStyle({
    required this.kind,
    required this.title,
    required this.showWarning,
    required this.outerBackground,
    required this.ribbonColor,
    required this.iconAsset,
    required this.titleColor,
    required this.valueColor,
    required this.labelColor,
    required this.dividerColor,
    required this.primaryButtonColor,
    required this.secondaryButtonColor,
  });

  final _ProgressCardKind kind;
  final String title;
  final bool showWarning;
  final Color outerBackground;
  final Color ribbonColor;
  final String iconAsset;
  final Color titleColor;
  final Color valueColor;
  final Color labelColor;
  final Color dividerColor;
  final Color primaryButtonColor;
  final Color secondaryButtonColor;

  static _ProgressCardStyle resolve(HomeProgressCardItem item) {
    if (item.orderStatus == 3) {
      return _ProgressCardStyle(
        kind: _ProgressCardKind.pastDue,
        title: item.orderStatusText.trim(),
        showWarning: true,
        outerBackground: Color(0xFFFED6D6),
        ribbonColor: Color(0xFFF9A7A2),
        iconAsset: 'assets/image/home/home_progress_error_icon.png',
        titleColor: Color(0xFF331707),
        valueColor: Color(0xFF281001),
        labelColor: Color(0xFF908E8C),
        dividerColor: Color(0xFFECE0D8),
        primaryButtonColor: Color(0xFFEF2E2C),
        secondaryButtonColor: Color(0xFFEF2E2C),
      );
    }
    if (item.orderStatus == 2) {
      return _ProgressCardStyle(
        kind: _ProgressCardKind.pendingPayment,
        title: item.orderStatusText.trim(),
        showWarning: true,
        outerBackground: Color(0xFFFED6D6),
        ribbonColor: Color(0xFFF9A7A2),
        iconAsset: 'assets/image/home/home_progress_error_icon.png',
        titleColor: Color(0xFF331707),
        valueColor: Color(0xFF281001),
        labelColor: Color(0xFF908E8C),
        dividerColor: Color(0xFFECE0D8),
        primaryButtonColor: Color(0xFFEF2E2C),
        secondaryButtonColor: Color(0xFFEF2E2C),
      );
    }
    if (item.orderStatus == 1) {
      return _ProgressCardStyle(
        kind: _ProgressCardKind.inReview,
        title: item.orderStatusText.trim(),
        showWarning: false,
        outerBackground: Color(0xFFFEEDCF),
        ribbonColor: Color(0xFFFDD49F),
        iconAsset: 'assets/image/home/home_progress_tip_icon.png',
        titleColor: Color(0xFF331707),
        valueColor: Color(0xFF281001),
        labelColor: Color(0xFF908E8C),
        dividerColor: Color(0xFFECE0D8),
        primaryButtonColor: Color(0xFFEFB440),
        secondaryButtonColor: Color(0xFFA3A09B),
      );
    }
    if (item.orderStatus == 5 || item.orderStatus == 6) {
      final hasMultipleActions =
          item.buttons.where((button) => button.enabled).length > 1;
      return _ProgressCardStyle(
        kind: hasMultipleActions
            ? _ProgressCardKind.failedDual
            : _ProgressCardKind.failedSingle,
        title: item.orderStatusText.trim(),
        showWarning: false,
        outerBackground: const Color(0xFFFEEDCF),
        ribbonColor: const Color(0xFFFDD49F),
        iconAsset: 'assets/image/home/home_progress_tip_icon.png',
        titleColor: const Color(0xFF331707),
        valueColor: const Color(0xFF281001),
        labelColor: const Color(0xFF908E8C),
        dividerColor: const Color(0xFFECE0D8),
        primaryButtonColor: const Color(0xFFEFB440),
        secondaryButtonColor: const Color(0xFFA3A09B),
      );
    }
    return _ProgressCardStyle(
      kind: _ProgressCardKind.releasingFunds,
      title: item.orderStatusText.trim(),
      showWarning: false,
      outerBackground: Color(0xFFFEEDCF),
      ribbonColor: Color(0xFFFDD49F),
      iconAsset: 'assets/image/home/home_progress_tip_icon.png',
      titleColor: Color(0xFF331707),
      valueColor: Color(0xFF281001),
      labelColor: Color(0xFF908E8C),
      dividerColor: Color(0xFFECE0D8),
      primaryButtonColor: Color(0xFFEFB440),
      secondaryButtonColor: Color(0xFFA3A09B),
    );
  }
}
