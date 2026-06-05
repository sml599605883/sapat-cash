import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../../core/json/json.dart';
import '../../core/layout/screen.dart';
import '../../core/network/api/api_client.dart';
import '../../core/network/core/error_message_adapter.dart';
import '../../core/push/route_names.dart';
import '../common/fetch_popup_handler.dart';
import '../main_tab/main_tab_controller.dart';
import 'home_models.dart';
import 'widgets/home_promo_banner.dart';
import 'widgets/home_progress_module.dart';
import 'widgets/home_recommendation_list.dart';
import 'widgets/home_top_section.dart';

typedef HomeDataFetcher = Future<AppHomeResponse?> Function();
typedef HomePopupFetcher = Future<Json> Function();
typedef HomePopupPresenter =
    Future<void> Function(BuildContext context, Json popupPayload);

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.fetchHomeData,
    this.fetchPopupPayload,
    this.showPopup,
  });

  static const routeName = RouteNames.home;
  final HomeDataFetcher? fetchHomeData;
  final HomePopupFetcher? fetchPopupPayload;
  final HomePopupPresenter? showPopup;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _lastRefreshToken = 0;
  bool _loading = false;
  bool _popupShowing = false;
  AppHomeResponse? _homeData;

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
    EasyLoading.show();
    try {
      final results = await Future.wait<dynamic>([
        _fetchHomeData(),
        _fetchPopupPayload(),
      ]);
      _homeData = results.first as AppHomeResponse?;
      final popupResponse = results[1] as Json;
      EasyLoading.dismiss();
      if (!_popupShowing && mounted) {
        _popupShowing = true;
        try {
          await _showPopup(popupResponse);
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
      EasyLoading.dismiss();
    }
  }

  Future<AppHomeResponse?> _fetchHomeData() async {
    final fetcher = widget.fetchHomeData;
    if (fetcher != null) {
      return fetcher();
    }
    return (await apiService.fetchAppHome()).data;
  }

  Future<Json> _fetchPopupPayload() async {
    final fetcher = widget.fetchPopupPayload;
    if (fetcher != null) {
      return fetcher();
    }
    return (await apiService.fetchPopup(scene: 1)).json;
  }

  Future<void> _showPopup(Json popupPayload) {
    final presenter = widget.showPopup;
    if (presenter != null) {
      return presenter(context, popupPayload);
    }
    return FetchPopupHandler.showIfNeeded(context, json: popupPayload);
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
              HomeTopSection(
                section: _homeData?.pretasted,
                icon: _homeData?.icon,
              ),
              HomePromoBanner(banners: _homeData?.banner ?? const []),
              HomeProgressModule(items: _homeData?.progressCard ?? const []),
              HomeRecommendationList(items: _homeData?.productList ?? const []),
              SizedBox(height: screen.dp(24)),
            ],
          ),
        ),
      ),
    );
  }
}
