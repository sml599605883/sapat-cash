import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/layout/screen.dart';
import '../home_models.dart';

class HomePromoBanner extends StatefulWidget {
  const HomePromoBanner({super.key, this.section});

  final HomeSection? section;

  @override
  State<HomePromoBanner> createState() => _HomePromoBannerState();
}

class _HomePromoBannerState extends State<HomePromoBanner> {
  static const _interval = Duration(seconds: 3);

  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  List<HomeSectionItem> get _banners =>
      widget.section?.items
          .where((item) => item.imageUrl?.trim().isNotEmpty == true)
          .toList() ??
      const [];

  @override
  void initState() {
    super.initState();
    _syncAutoPlay();
  }

  @override
  void didUpdateWidget(covariant HomePromoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
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
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    if (banners.length == 1) {
      return _BannerImage(
        width: width,
        height: width * (120.0 / 343.0),
        imageUrl: banners.first.imageUrl!,
      );
    }

    return SizedBox(
      width: width,
      height: width * (120.0 / 343.0),
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
              width: screen.dp(343),
              height: screen.dp(120),
              imageUrl: banners[index].imageUrl!,
            );
          },
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({
    required this.width,
    required this.height,
    required this.imageUrl,
  });

  final double width;
  final double height;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}
