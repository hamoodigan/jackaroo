import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Small responsive toolkit: breakpoints and a size scaler, so screens can
/// adapt to phones, tablets and desktops without per-widget math.
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get shortestSide => screenSize.shortestSide;

  /// Material's tablet breakpoint.
  bool get isTablet => shortestSide >= 600;

  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Scales a dimension designed for a ~390dp-wide phone to the current
  /// screen, clamped so tablets don't balloon and small phones stay usable.
  ///
  ///     width: context.rs(130)           // 130 on a normal phone
  ///     width: context.rs(130, max: 180)
  double rs(double base, {double? min, double? max}) {
    final v = base * (shortestSide / 390.0);
    return v.clamp(min ?? base * 0.8, max ?? base * 1.45);
  }

  /// Largest square that fits [cons] minus [padding] on every side —
  /// used to size the board.
  double squareFit(BoxConstraints cons, {double padding = 0}) =>
      math.min(cons.maxWidth, cons.maxHeight) - padding * 2;
}
