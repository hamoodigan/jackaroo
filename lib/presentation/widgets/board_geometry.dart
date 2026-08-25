import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../domain/entities/position.dart';

/// Maps every logical location (track hole, home slot, waiting slot) to a
/// point on the classic cross-shaped Jackaroo board.
///
/// The track runs CLOCKWISE around the outline of a plus sign: each arm
/// carries 19 holes (7 up one side, 5 across the tip, 7 back down). Seat 0
/// owns the bottom arm, seat 1 the left, seat 2 the top, seat 3 the right.
/// A seat's entry hole is the centre of its arm tip, the 4 home holes run
/// from the tip toward the centre, and the 4 waiting holes sit in a 2×2
/// pocket outside the cross, in the corner between two arms.
class BoardGeometry {
  final double size;

  /// Hole pitch.
  late final double d;
  late final double cellRadius;
  late final double marbleRadius;

  /// Half-width of an arm and reach from centre to arm tip (both in px).
  late final double armHalf;
  late final double reach;

  BoardGeometry(this.size) {
    d = size / (2 * _reachUnits + 2 * _marginUnits);
    armHalf = _armHalfUnits * d;
    reach = _reachUnits * d;
    cellRadius = d * 0.34;
    marbleRadius = d * 0.42;
  }

  static const _n = GameConfig.cellsPerSide; // 19
  static const double _armHalfUnits = 2.5; // tip holds 5 holes
  static const double _reachUnits = 9.5; // 7 + 2.5
  static const double _marginUnits = 1.5;
  static const int _sideHoles = 7;
  static const int _tipHoles = 5;

  Offset get centre => Offset(size / 2, size / 2);

  /// Unit vector from an arm's tip toward the board centre.
  static const inward = [
    Offset(0, -1), // bottom arm
    Offset(1, 0), // left arm
    Offset(0, 1), // top arm
    Offset(-1, 0), // right arm
  ];

  /// Clockwise walk of one arm: [side out, across tip, side back].
  static const _dirs = [
    [Offset(0, 1), Offset(-1, 0), Offset(0, -1)], // bottom
    [Offset(-1, 0), Offset(0, -1), Offset(1, 0)], // left
    [Offset(0, -1), Offset(1, 0), Offset(0, 1)], // top
    [Offset(1, 0), Offset(0, 1), Offset(-1, 0)], // right
  ];

  /// Concave corner where each arm's walk starts.
  Offset _start(int arm) {
    final a = armHalf;
    return centre +
        switch (arm) {
          0 => Offset(a, a),
          1 => Offset(-a, a),
          2 => Offset(-a, -a),
          _ => Offset(a, -a),
        };
  }

  Offset trackCell(int abs) {
    final arm = abs ~/ _n, k = abs % _n;
    final dirs = _dirs[arm];
    // Holes sit half a pitch past each corner, so the tip's middle hole
    // (k = 9) lands exactly on the arm's centre line.
    var p = _start(arm);
    var left = (k + 0.5) * d;
    const lens = [_sideHoles * 1.0, _tipHoles * 1.0, _sideHoles * 1.0];
    for (var seg = 0; seg < 3 && left > 0; seg++) {
      final take = left < lens[seg] * d ? left : lens[seg] * d;
      p += dirs[seg] * take;
      left -= take;
    }
    return p;
  }

  /// Centre of a seat's arm tip (its entry hole).
  Offset tip(int seat) => centre - inward[seat] * reach;

  Offset entryCell(int seat) => trackCell(Pos.entryCell(seat));

  Offset homeCell(int seat, int i) => tip(seat) + inward[seat] * ((i + 1) * d);

  /// 2×2 waiting pocket OUTSIDE the cross, in the corner just before the
  /// seat's arm (clockwise). Only marbles heading home enter the middle.
  Offset baseCell(int seat, int i) {
    final corner = _start(seat) - centre; // (±a, ±a)
    final sx = corner.dx.sign, sy = corner.dy.sign;
    final c = centre + Offset(sx * (armHalf + 2.4 * d), sy * (armHalf + 2.4 * d));
    final dx = (i % 2 == 0 ? -0.55 : 0.55) * d;
    final dy = (i < 2 ? -0.55 : 0.55) * d;
    return c + Offset(dx, dy);
  }

  Offset locate(int seat, int pos, int idx) {
    if (Pos.isBase(pos)) return baseCell(seat, idx);
    if (Pos.isHome(pos)) return homeCell(seat, Pos.homeIndex(pos));
    return trackCell(Pos.abs(seat, pos));
  }

  /// Outline of the plus, inflated by [pad] px, as a rounded path.
  Path crossPath(double pad, double radius) {
    final c = centre;
    final a = armHalf + pad, r = reach + pad;
    final pts = <Offset>[
      Offset(-a, -r), Offset(a, -r), Offset(a, -a), Offset(r, -a),
      Offset(r, a), Offset(a, a), Offset(a, r), Offset(-a, r),
      Offset(-a, a), Offset(-r, a), Offset(-r, -a), Offset(-a, -a),
    ].map((o) => c + o).toList();
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final prev = pts[(i - 1 + pts.length) % pts.length];
      final cur = pts[i];
      final next = pts[(i + 1) % pts.length];
      final inDir = (cur - prev) / (cur - prev).distance;
      final outDir = (next - cur) / (next - cur).distance;
      final p1 = cur - inDir * radius;
      final p2 = cur + outDir * radius;
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }
}
