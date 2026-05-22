import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../../core/layout/screen.dart';
import '../../core/network/api/api_client.dart';
import '../../core/network/config/network_config.dart';
import '../../core/network/core/error_message_adapter.dart';
import '../../core/push/app_push.dart';
import '../../core/push/route_names.dart';
import '../auth/auth_controller.dart';
import '../common/fetch_popup_handler.dart';
import '../main_tab/main_tab_controller.dart';
import '../orders/order_list_page.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  static const routeName = RouteNames.mine;

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  int _lastRefreshToken = 0;
  bool _loading = false;
  bool _popupShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshMineData();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _refreshMineData() async {
    final refreshToken = context.read<MainTabController>().mineRefreshToken;
    if (_loading) {
      return;
    }
    _loading = true;
    _lastRefreshToken = refreshToken;
    try {
      final response = await apiService.fetchPopup(scene: 2);
      if (!_popupShowing && mounted) {
        _popupShowing = true;
        try {
          await FetchPopupHandler.showIfNeeded(context, json: response.json);
        } finally {
          _popupShowing = false;
        }
      }
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      if (mounted) {
        setState(() {});
      }
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final refreshToken = context.select<MainTabController, int>(
      (controller) => controller.mineRefreshToken,
    );

    if (_lastRefreshToken != refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastRefreshToken != refreshToken) {
          _refreshMineData();
        }
      });
    }

    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(bottom: false, child: SizedBox(height: screen.dp(26))),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  screen.dp(16),
                  0,
                  screen.dp(16),
                  0,
                ),
                child: const _MineProfileHeader(),
              ),
              SizedBox(height: screen.dp(26)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
                child: const _MineStatsCard(),
              ),
              SizedBox(height: screen.dp(26)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
                child: const _MineSectionHeader(),
              ),
              SizedBox(height: screen.dp(16)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screen.dp(16)),
                child: const _MineMenuList(),
              ),
              SizedBox(height: screen.dp(120)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MineProfileHeader extends StatelessWidget {
  const _MineProfileHeader();

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final phone = context.select<AuthController, String>(
      (controller) => controller.phone,
    );

    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/image/mine/mine_avatar.png',
            width: screen.dp(76),
            height: screen.dp(76),
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: screen.dp(16)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _maskedPhone(phone),
              style: TextStyle(
                color: const Color(0xFF281001),
                fontSize: screen.dp(24),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screen.dp(10)),
            Text(
              'User ID:',
              style: TextStyle(
                color: const Color(0xFF908E8C),
                fontSize: screen.dp(16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _maskedPhone(String phone) {
    final normalized = phone.trim();
    if (normalized.length < 7) {
      return normalized.isEmpty ? '---' : normalized;
    }
    final prefix = normalized.substring(0, 3);
    final suffix = normalized.substring(normalized.length - 4);
    return '$prefix****$suffix';
  }
}

class _MineStatsCard extends StatelessWidget {
  const _MineStatsCard();

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        screen.dp(30),
        screen.dp(26),
        screen.dp(30),
        screen.dp(26),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E1),
        borderRadius: BorderRadius.circular(screen.dp(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MineStatItem(
            icon: 'assets/image/mine/mine_icon_1@3x.png',
            label: 'All',
            type: OrderListType.all,
          ),
          _MineStatItem(
            icon: 'assets/image/mine/mine_icon_2@3x.png',
            label: 'Outstanding',
            type: OrderListType.outstanding,
          ),
          _MineStatItem(
            icon: 'assets/image/mine/mine_icon_3@3x.png',
            label: 'Settled',
            type: OrderListType.settled,
          ),
        ],
      ),
    );
  }
}

class _MineStatItem extends StatelessWidget {
  const _MineStatItem({
    required this.icon,
    required this.label,
    required this.type,
  });

  final String icon;
  final String label;
  final OrderListType type;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => AppPush.push(
        context,
        page: OrderListPage(initialType: type),
        routeName: OrderListPage.routeName,
      ),
      child: Column(
        children: [
          Image.asset(icon, width: screen.dp(56), height: screen.dp(56)),
          SizedBox(height: screen.dp(10)),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF331707),
              fontSize: screen.dp(16),
            ),
          ),
        ],
      ),
    );
  }
}

class _MineSectionHeader extends StatelessWidget {
  const _MineSectionHeader();

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Row(
      children: [
        Image.asset(
          'assets/image/mine/mine_badge_dot.png',
          width: screen.dp(16),
          height: screen.dp(16),
        ),
        SizedBox(width: screen.dp(10)),
        Text(
          'Our service',
          style: TextStyle(
            color: const Color(0xFF281001),
            fontSize: screen.dp(18),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MineMenuList extends StatelessWidget {
  const _MineMenuList();

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Column(
      children: [
        _MineMenuItem(
          icon: 'assets/image/mine/mine_contact_icon.png',
          title: 'Customer service',
          onTap: () => AppPush.pushWebView(
            context,
            url: '${NetworkConfig.defaultWebBaseUrl}/#/OsteotomesLensless',
          ),
        ),
        SizedBox(height: screen.dp(16)),
        _MineMenuItem(
          icon: 'assets/image/mine/mine_settings_icon.png',
          title: 'Account',
          onTap: () => AppPush.pushAccount(context),
        ),
        SizedBox(height: screen.dp(16)),
        _MineMenuItem(
          icon: 'assets/image/mine/mine_privacy_icon.png',
          title: 'Privacy',
          onTap: () => AppPush.pushWebView(
            context,
            url: '${NetworkConfig.defaultWebBaseUrl}/#/PhotoreceptionsTressels',
          ),
        ),
      ],
    );
  }
}

class _MineMenuItem extends StatelessWidget {
  const _MineMenuItem({required this.icon, required this.title, this.onTap});

  final String icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          screen.dp(16),
          screen.dp(11),
          screen.dp(16),
          screen.dp(11),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(screen.dp(14)),
        ),
        child: Row(
          children: [
            Image.asset(icon, width: screen.dp(30), height: screen.dp(30)),
            SizedBox(width: screen.dp(16)),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF331707),
                fontSize: screen.dp(16),
                height: 20 / 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
