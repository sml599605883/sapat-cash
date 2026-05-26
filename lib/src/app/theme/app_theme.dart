import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brandPrimary,
    required this.homeCardBackground,
    required this.homeTitle,
    required this.homeBody,
    required this.homeMetricLabel,
    required this.homeMetricValue,
    required this.homeFallback,
    required this.homeFallbackBorder,
    required this.homeButtonDisabled,
    required this.homeProgressIndicatorInactive,
    required this.homeProgressShadow,
    required this.homeProgressAlertShadow,
  });

  final Color brandPrimary;
  final Color homeCardBackground;
  final Color homeTitle;
  final Color homeBody;
  final Color homeMetricLabel;
  final Color homeMetricValue;
  final Color homeFallback;
  final Color homeFallbackBorder;
  final Color homeButtonDisabled;
  final Color homeProgressIndicatorInactive;
  final Color homeProgressShadow;
  final Color homeProgressAlertShadow;

  @override
  AppPalette copyWith({
    Color? brandPrimary,
    Color? homeCardBackground,
    Color? homeTitle,
    Color? homeBody,
    Color? homeMetricLabel,
    Color? homeMetricValue,
    Color? homeFallback,
    Color? homeFallbackBorder,
    Color? homeButtonDisabled,
    Color? homeProgressIndicatorInactive,
    Color? homeProgressShadow,
    Color? homeProgressAlertShadow,
  }) {
    return AppPalette(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      homeCardBackground: homeCardBackground ?? this.homeCardBackground,
      homeTitle: homeTitle ?? this.homeTitle,
      homeBody: homeBody ?? this.homeBody,
      homeMetricLabel: homeMetricLabel ?? this.homeMetricLabel,
      homeMetricValue: homeMetricValue ?? this.homeMetricValue,
      homeFallback: homeFallback ?? this.homeFallback,
      homeFallbackBorder: homeFallbackBorder ?? this.homeFallbackBorder,
      homeButtonDisabled: homeButtonDisabled ?? this.homeButtonDisabled,
      homeProgressIndicatorInactive:
          homeProgressIndicatorInactive ?? this.homeProgressIndicatorInactive,
      homeProgressShadow: homeProgressShadow ?? this.homeProgressShadow,
      homeProgressAlertShadow:
          homeProgressAlertShadow ?? this.homeProgressAlertShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      homeCardBackground: Color.lerp(
        homeCardBackground,
        other.homeCardBackground,
        t,
      )!,
      homeTitle: Color.lerp(homeTitle, other.homeTitle, t)!,
      homeBody: Color.lerp(homeBody, other.homeBody, t)!,
      homeMetricLabel: Color.lerp(homeMetricLabel, other.homeMetricLabel, t)!,
      homeMetricValue: Color.lerp(homeMetricValue, other.homeMetricValue, t)!,
      homeFallback: Color.lerp(homeFallback, other.homeFallback, t)!,
      homeFallbackBorder: Color.lerp(
        homeFallbackBorder,
        other.homeFallbackBorder,
        t,
      )!,
      homeButtonDisabled: Color.lerp(
        homeButtonDisabled,
        other.homeButtonDisabled,
        t,
      )!,
      homeProgressIndicatorInactive: Color.lerp(
        homeProgressIndicatorInactive,
        other.homeProgressIndicatorInactive,
        t,
      )!,
      homeProgressShadow: Color.lerp(
        homeProgressShadow,
        other.homeProgressShadow,
        t,
      )!,
      homeProgressAlertShadow: Color.lerp(
        homeProgressAlertShadow,
        other.homeProgressAlertShadow,
        t,
      )!,
    );
  }
}

ThemeData buildAppTheme() {
  const palette = AppPalette(
    brandPrimary: Color(0xFFF45834),
    homeCardBackground: Color(0xFFF5F5F3),
    homeTitle: Color(0xFF281001),
    homeBody: Color(0xFF3F3E3A),
    homeMetricLabel: Color(0xFF3F3E3A),
    homeMetricValue: Color(0xFF281001),
    homeFallback: Color(0xFFD8D8D8),
    homeFallbackBorder: Color(0xFF979797),
    homeButtonDisabled: Color(0xFFA3A09B),
    homeProgressIndicatorInactive: Color(0xFFE0DDDA),
    homeProgressShadow: Color(0x14000000),
    homeProgressAlertShadow: Color(0x59F7622E),
  );

  return ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: palette.brandPrimary),
    extensions: const [palette],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
