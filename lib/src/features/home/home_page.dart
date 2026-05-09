import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../../core/layout/screen.dart';
import '../../core/network/api/api_client.dart';
import '../../core/network/core/error_message_adapter.dart';
import '../main_tab/main_tab_controller.dart';
import 'widgets/home_promo_banner.dart';
import 'widgets/home_top_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _lastRefreshToken = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshHomeData();
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _onRefresh() async {
    await _refreshHomeData();
  }

  Future<void> _refreshHomeData() async {
    final refreshToken = context.read<MainTabController>().homeRefreshToken;
    if (_loading) {
      return;
    }
    _loading = true;
    _lastRefreshToken = refreshToken;
    EasyLoading.show(status: 'Loading...');
    try {
      await ApiClient.initialize();
      await Future.wait([
        apiService.fetchAppHome(),
        apiService.fetchPopup(scene: 1),
      ]);
    } catch (error) {
      EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
    } finally {
      if (mounted) {
        setState(() {});
      }
      _loading = false;
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final refreshToken = context.select<MainTabController, int>(
      (controller) => controller.homeRefreshToken,
    );

    if (_lastRefreshToken != refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastRefreshToken != refreshToken) {
          _refreshHomeData();
        }
      });
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screen.height - screen.safeBottom,
          ),
          child: Column(
            children: [
              const HomeTopSection(),
              const HomePromoBanner(),
              SizedBox(height: screen.dp(24)),
            ],
          ),
        ),
      ),
    );
  }
}
