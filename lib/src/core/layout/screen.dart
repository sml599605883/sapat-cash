import 'package:flutter/widgets.dart';

extension ScreenX on BuildContext {
  ScreenData get screen => ScreenData._(MediaQuery.of(this));
}

class ScreenData {
  const ScreenData._(this._mediaQuery);

  final MediaQueryData _mediaQuery;

  double get width => _mediaQuery.size.width;
  double get height => _mediaQuery.size.height;
  double get safeTop => _mediaQuery.padding.top;
  double get safeBottom => _mediaQuery.padding.bottom;
  double get scale => width / 375.0;

  double dp(num value) => value * scale;
}
