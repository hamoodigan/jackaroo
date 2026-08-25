import 'package:flutter_test/flutter_test.dart';
import 'package:jackaroo/core/config/game_config.dart';
import 'package:jackaroo/domain/entities/position.dart';
import 'package:jackaroo/presentation/widgets/board_geometry.dart';

void main() {
  final g = BoardGeometry(476); // p = 20 px
  final track = List.generate(GameConfig.trackLength, g.trackCell);

  test('76 distinct holes, every consecutive pair exactly one pitch apart', () {
    for (var i = 0; i < track.length; i++) {
      final next = track[(i + 1) % track.length];
      expect((next - track[i]).distance, closeTo(g.p, 0.05), reason: 'hole $i');
      for (var j = i + 1; j < track.length; j++) {
        expect((track[j] - track[i]).distance > g.p * 0.9, isTrue,
            reason: 'holes $i and $j overlap');
      }
    }
  });

  test('clockwise: seat 0 base is bottom-right, next hole heads left', () {
    final e = g.trackCell(Pos.entryCell(0));
    expect(e.dx, greaterThan(g.centre.dx));
    expect(e.dy, greaterThan(g.centre.dy));
    final n = g.trackCell(Pos.entryCell(0) + 1);
    expect(n.dx, lessThan(e.dx));
  });

  test('seats are 90° rotations of each other', () {
    for (var s = 0; s < 4; s++) {
      final a = g.trackCell(Pos.entryCell(s)) - g.centre;
      final b = g.trackCell(Pos.entryCell((s + 1) % 4)) - g.centre;
      // rotating a by 90° clockwise (y down) gives (-y, x)
      expect(b.dx, closeTo(-a.dy, 0.05));
      expect(b.dy, closeTo(a.dx, 0.05));
    }
  });

  test('home lanes and pockets never overlap the track', () {
    for (var s = 0; s < 4; s++) {
      final pts = [
        for (var i = 0; i < GameConfig.homeSize; i++) g.homeCell(s, i),
        for (var i = 0; i < GameConfig.marblesPerPlayer; i++) g.baseCell(s, i),
      ];
      for (final h in pts) {
        for (final t in track) {
          expect((t - h).distance > g.p * 0.9, isTrue, reason: 'seat $s');
        }
        expect((h - g.centre).distance < g.apothem - g.p, isTrue,
            reason: 'inside the octagon');
      }
    }
  });

  test('home lane starts one pitch past the threshold hole (rel 75)', () {
    for (var s = 0; s < 4; s++) {
      final threshold = g.trackCell(Pos.abs(s, GameConfig.trackLength - 1));
      expect((g.homeCell(s, 0) - threshold).distance, closeTo(g.p, 0.05));
      expect((g.homeCell(s, 3) - g.centre).distance,
          lessThan((g.homeCell(s, 0) - g.centre).distance));
    }
  });
}
