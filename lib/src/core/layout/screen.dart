import 'package:flutter/widgets.dart';

extension ScreenX on BuildContext {
  ScreenData get screen => ScreenData._(MediaQuery.of(this));
}

class ScreenData {
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  const ScreenData._(this._mediaQuery);

  final MediaQueryData _mediaQuery;

  double get width => _mediaQuery.size.width;
  double get height => _mediaQuery.size.height;
  double get safeTop => _mediaQuery.padding.top;
  double get safeBottom => _mediaQuery.padding.bottom;
  double get widthScale => width / _designWidth;
  double get heightScale => height / _designHeight;

  // Keep the UI aligned to the 375x812 design draft on larger devices
  // and only shrink proportionally on smaller screens.
  double get scale => widthScale < heightScale
      ? widthScale.clamp(0.0, 1.0)
      : heightScale.clamp(0.0, 1.0);

  double dp(num value) => value * scale;
}
