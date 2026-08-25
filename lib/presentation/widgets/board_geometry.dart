import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../domain/entities/position.dart';

/// Maps every logical location (track cell, home slot, base slot) to a
/// point on a square board of [size] pixels. Seat 0 is at the bottom and
/// play goes counter-clockwise.
class BoardGeometry {
  final double size;
  late final double margin;
  late final double d; // cell pitch
  late final double cellRadius;
  late final double marbleRadius;

  BoardGeometry(this.size) {
    margin = size * 0.075;
    d = (size - margin * 2) / GameConfig.cellsPerSide;
    cellRadius = d * 0.34;
    marbleRadius = d * 0.42;
  }

  static const _n = GameConfig.cellsPerSide;

  /// Unit vector pointing from a side toward the centre.
  static const _inward = [
    Offset(0, -1), // bottom
    Offset(-1, 0), // right
    Offset(0, 1), // top
    Offset(1, 0), // left
  ];

  /// Direction of travel along a side.
  static const _along = [
    Offset(1, 0),
    Offset(0, -1),
    Offset(-1, 0),
    Offset(0, 1),
  ];

  /// Corner where side [s] starts (k = 0).
  Offset _corner(int s) {
    final lo = margin + d / 2, hi = size - margin - d / 2;
    return switch (s) {
      0 => Offset(lo, hi),
      1 => Offset(hi, hi),
      2 => Offset(hi, lo),
      _ => Offset(lo, lo),
    };
  }

  Offset trackCell(int abs) {
    final side = abs ~/ _n, k = abs % _n;
    return _corner(side) + _along[side] * (k * d);
  }

  Offset homeCell(int seat, int i) {
    final threshold = trackCell(Pos.abs(seat, GameConfig.trackLength - 1));
    return threshold + _inward[seat] * ((i + 1) * d);
  }

  /// 2×2 cluster of waiting slots tucked into each seat's start corner.
  Offset baseCell(int seat, int i) {
    final c = _corner(seat);
    final inward = _inward[seat];
    final along = _along[seat];
    final centre = c + (inward + along) * (d * 2.4);
    final dx = (i % 2 == 0 ? -0.55 : 0.55) * d;
    final dy = (i < 2 ? -0.55 : 0.55) * d;
    return centre + Offset(dx, dy);
  }

  Offset entryCell(int seat) => trackCell(Pos.entryCell(seat));

  /// Point for a marble of [seat] at encoded [pos] (slot [idx] when in base).
  Offset locate(int seat, int pos, int idx) {
    if (Pos.isBase(pos)) return baseCell(seat, idx);
    if (Pos.isHome(pos)) return homeCell(seat, Pos.homeIndex(pos));
    return trackCell(Pos.abs(seat, pos));
  }

  Offset get centre => Offset(size / 2, size / 2);
}
