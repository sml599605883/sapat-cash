import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sapat_cash/src/core/network/api/api_client.dart';

import '../../../core/layout/screen.dart';
import '../../../core/push/app_push.dart';
import '../home_models.dart';

class HomePromoBanner extends StatefulWidget {
  const HomePromoBanner({super.key, this.banners = const []});

  final List<HomeBannerItem> banners;

  @override
  State<HomePromoBanner> createState() => _HomePromoBannerState();
}

class _HomePromoBannerState extends State<HomePromoBanner> {
  static const _interval = Duration(seconds: 3);

  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  List<HomeBannerItem> get _banners =>
      widget.banners.where((item) => item.imageUrl.trim().isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    _syncAutoPlay();
  }

  @override
  void didUpdateWidget(covariant HomePromoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners != widget.banners) {
      _currentIndex = 0;
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

  void _syncAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_banners.length <= 1) {
      return;
    }
    _autoPlayTimer = Timer.periodic(_interval, (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextIndex = (_currentIndex + 1) % _banners.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final banners = _banners;
    final width = screen.width - screen.dp(16) * 2;
    final height = width * (120.0 / 343.0);
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    if (banners.length == 1) {
      return _BannerImage(
        width: width,
        height: height,
        imageUrl: banners.first.imageUrl,
        onTap: () => _handleBannerTap(banners.first),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screen.dp(14)),
        child: PageView.builder(
          controller: _pageController,
          itemCount: banners.length,
          onPageChanged: (index) {
            _currentIndex = index;
          },
          itemBuilder: (context, index) {
            return _BannerImage(
              width: width,
              height: height,
              imageUrl: banners[index].imageUrl,
              onTap: () => _handleBannerTap(banners[index]),
            );
          },
        ),
      ),
    );
  }

  void _handleBannerTap(HomeBannerItem item) {
    final link = item.link.trim();
    if (link.isEmpty) {
      return;
    }
    if (item.bannerConfigId.isNotEmpty) {
      apiService.uploadBannerClickRecord(
        bannerConfigId: item.bannerConfigId.trim(),
      );
    }
    AppPush.pushWebView(context, url: link);
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({
    required this.width,
    required this.height,
    required this.imageUrl,
    required this.onTap,
  });

  final double width;
  final double height;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/image/home/home_banner_promo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
