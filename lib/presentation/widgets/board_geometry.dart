import 'dart:math' as math;
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../domain/entities/position.dart';

/// Geometry of the classic octagonal Jackaroo board (traced from a photo of
/// the real board).
///
/// The track is a loop of 76 holes with eight apexes: four straight
/// diagonal edges (5 holes) and four dented orthogonal sides (5 holes
/// diagonally in, 6 straight, 5 diagonally out). Marbles travel CLOCKWISE.
/// Each seat owns one diagonal corner: its base (entry) hole is the 4th hole
/// of that diagonal edge, the 4 home holes run from the previous hole along
/// the corner's diagonal toward the centre, and its 4 waiting holes form a
/// diamond in the notch of the next orthogonal side.
///
/// Seat 0 = bottom-right corner (bottom side), 1 = bottom-left, 2 = top-left,
/// 3 = top-right — consecutive seats follow the direction of play.
class BoardGeometry {
  final double size;

  /// Hole pitch in px.
  late final double p;
  late final double cellRadius;
  late final double marbleRadius;

  /// Apothem of the wooden octagon, in pitches.
  static const double apothemUnits = 11.9;

  BoardGeometry(this.size) {
    p = size / (2 * apothemUnits);
    cellRadius = p * 0.36;
    marbleRadius = p * 0.44;
  }

  Offset get centre => Offset(size / 2, size / 2);
  double get apothem => apothemUnits * p;

  static const double _s = 0.70710678; // diagonal step per axis
  static const double _halfRow = 2.5; // straight run: x = -2.5 … 2.5
  static const double _ax = _halfRow + 5 * _s; // apex |x|  = 6.0355
  static const double _ay = _ax + 4 * _s; // apex |y|  = 8.8639
  static const double _rowY = _ay - 5 * _s; // straight run y = 5.3284

  /// Template for the TOP-LEFT seat (quadrant 0), in pitches, y down.
  /// Index = relative position from the base hole (0 … 18).
  static final List<Offset> _track = _buildTrack();

  static List<Offset> _buildTrack() {
    const apex0 = Offset(-_ax, -_ay);
    const apex1 = Offset(_ax, -_ay);
    final t = <Offset>[];
    t.add(apex0 + const Offset(-_s, _s)); // 0 base hole (on the diagonal edge)
    t.add(apex0); // 1
    for (var k = 1; k <= 4; k++) {
      t.add(apex0 + Offset(k * _s, k * _s)); // 2..5 diagonally in
    }
    for (var i = 0; i < 6; i++) {
      t.add(Offset(-_halfRow + i, -_rowY)); // 6..11 straight
    }
    for (var k = 1; k <= 4; k++) {
      t.add(Offset(_halfRow + k * _s, -_rowY - k * _s)); // 12..15 out
    }
    t.add(apex1); // 16
    t.add(apex1 + const Offset(_s, _s)); // 17
    t.add(apex1 + const Offset(2 * _s, 2 * _s)); // 18
    assert(t.length == GameConfig.cellsPerSide);
    return t;
  }

  /// Threshold hole (rel −1) of the template seat.
  static final Offset _threshold = _track[0] + const Offset(-_s, _s);

  static final List<Offset> _home = List.generate(
    GameConfig.homeSize,
    (i) => _threshold + Offset((i + 1) * _s, (i + 1) * _s),
  );

  /// Diamond of waiting holes in the top notch, pulled toward the seat's
  /// base hole (as on the real board).
  static const Offset _pocketCentre = Offset(-2.4, -7.9);
  static const List<Offset> _pocket = [
    Offset(0, -0.85),
    Offset(-0.85, 0),
    Offset(0.85, 0),
    Offset(0, 0.85),
  ];

  /// Quarter-turns (clockwise) applied to the template for each seat.
  static const List<int> _turns = [2, 3, 0, 1];

  static Offset _rot(Offset u, int quarterTurns) {
    var o = u;
    for (var i = 0; i < quarterTurns; i++) {
      o = Offset(-o.dy, o.dx); // 90° clockwise on screen
    }
    return o;
  }

  Offset _place(Offset unit, int seat) =>
      centre + _rot(unit, _turns[seat]) * p;

  Offset trackCell(int abs) {
    final seat = abs ~/ GameConfig.cellsPerSide;
    final k = abs % GameConfig.cellsPerSide;
    return _place(_track[k], seat);
  }

  Offset homeCell(int seat, int i) => _place(_home[i], seat);

  Offset baseCell(int seat, int i) =>
      _place(_pocketCentre + _pocket[i], seat);

  Offset pocketCentre(int seat) => _place(_pocketCentre, seat);

  Offset entryCell(int seat) => trackCell(Pos.entryCell(seat));

  Offset locate(int seat, int pos, int idx) {
    if (Pos.isBase(pos)) return baseCell(seat, idx);
    if (Pos.isHome(pos)) return homeCell(seat, Pos.homeIndex(pos));
    return trackCell(Pos.abs(seat, pos));
  }

  /// Regular octagon with the given apothem (px), flat sides top/bottom.
  Path octagon(double apothem, {double corner = 0}) {
    final r = apothem / math.cos(math.pi / 8);
    final pts = List.generate(8, (i) {
      final a = math.pi / 8 + i * math.pi / 4;
      return centre + Offset(math.cos(a), math.sin(a)) * r;
    });
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final prev = pts[(i + 7) % 8], cur = pts[i], next = pts[(i + 1) % 8];
      if (corner <= 0) {
        if (i == 0) {
          path.moveTo(cur.dx, cur.dy);
        } else {
          path.lineTo(cur.dx, cur.dy);
        }
        continue;
      }
      final din = (cur - prev) / (cur - prev).distance;
      final dout = (next - cur) / (next - cur).distance;
      final p1 = cur - din * corner, p2 = cur + dout * corner;
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
