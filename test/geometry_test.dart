import 'package:flutter_test/flutter_test.dart';
import 'package:jackaroo/core/config/game_config.dart';
import 'package:jackaroo/domain/entities/position.dart';
import 'package:jackaroo/presentation/widgets/board_geometry.dart';

void main() {
  test('cross track: 76 distinct holes, each one pitch apart, clockwise', () {
    final g = BoardGeometry(400);
    final pts = List.generate(GameConfig.trackLength, g.trackCell);
    for (var i = 0; i < pts.length; i++) {
      final next = pts[(i + 1) % pts.length];
      final dist = (next - pts[i]).distance;
      // Straight hop = one pitch; hop around a 90° corner = 0.707 pitch.
      expect(dist, anyOf(closeTo(g.d, 0.01), closeTo(g.d * 0.7071, 0.01)),
          reason: 'hole $i');
      for (var j = i + 1; j < pts.length; j++) {
        expect((pts[j] - pts[i]).distance > g.d * 0.5, isTrue,
            reason: 'holes $i and $j overlap');
      }
    }
    // Entry of seat 0 is the bottom tip centre; next hole is to its left
    // (clockwise on screen).
    final e = g.trackCell(Pos.entryCell(0));
    expect(e.dx, closeTo(200, 0.01));
    expect(e.dy, greaterThan(300));
    final n = g.trackCell(Pos.entryCell(0) + 1);
    expect(n.dx, lessThan(e.dx));
    // Home column heads toward the centre and stays clear of the track.
    for (var s = 0; s < 4; s++) {
      for (var i = 0; i < 4; i++) {
        final h = g.homeCell(s, i);
        for (final p in pts) {
          expect((p - h).distance > g.d * 0.9, isTrue, reason: 'seat $s home $i');
        }
      }
    }
  });
}
