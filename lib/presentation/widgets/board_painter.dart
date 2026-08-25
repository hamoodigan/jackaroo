import 'package:flutter/material.dart';

import '../../core/config/game_config.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/position.dart';
import 'board_geometry.dart';

/// Static board art: mahogany octagon, cream holes, coloured base holes,
/// tinted home lanes, waiting pockets and the cream centre octagon where
/// the played card sits. Repainted only when the size changes.
class BoardPainter extends CustomPainter {
  final BoardGeometry g;
  BoardPainter(this.g);

  static const Color mahogany = Color(0xFF5C1F22);
  static const Color mahoganyDark = Color(0xFF3A1114);
  static const Color mahoganyLight = Color(0xFF7A2C30);
  static const Color cream = Color(0xFFE9DCB8);
  static const Color creamDark = Color(0xFFCBB98F);
  static const Color holeShadow = Color(0xFF2A0B0D);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & Size(g.size, g.size);
    final outer = g.octagon(g.apothem, corner: g.p * 0.35);

    // Shadow + wood.
    canvas.drawPath(
        outer.shift(Offset(0, g.p * 0.3)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.p * 0.6));
    canvas.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mahoganyLight, mahogany, mahoganyDark],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    // Grain.
    canvas.save();
    canvas.clipPath(outer);
    final grain = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i < 40; i++) {
      final x = g.size * (i / 40) + (i % 3) * 1.5;
      canvas.drawLine(Offset(x, 0), Offset(x + g.size * 0.03, g.size), grain);
    }
    // Centre fold line like the real folding board.
    canvas.drawLine(
        Offset(g.size / 2, 0),
        Offset(g.size / 2, g.size),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..strokeWidth = g.p * 0.12);
    canvas.restore();
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppTheme.gold.withValues(alpha: 0.5),
    );

    _drawPockets(canvas);
    _drawHomeLanes(canvas);
    _drawTrack(canvas);
    _drawCentre(canvas);
  }

  void _hole(Canvas canvas, Offset c, double r, {Color? ring, Color? fill}) {
    // Recessed look: dark rim below, cream disc, subtle inner shade.
    canvas.drawCircle(
        c.translate(0, r * 0.22),
        r * 1.05,
        Paint()..color = holeShadow.withValues(alpha: 0.7));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [fill ?? cream, fill == null ? creamDark : fill.withValues(alpha: 0.7)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    if (ring != null) {
      canvas.drawCircle(
          c,
          r * 1.9,
          Paint()
            ..color = ring.withValues(alpha: 0.35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9));
      canvas.drawCircle(
          c,
          r * 1.25,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.22
            ..color = ring);
    }
  }

  void _drawTrack(Canvas canvas) {
    final r = g.cellRadius;
    for (var i = 0; i < GameConfig.trackLength; i++) {
      Color? ring;
      for (var seat = 0; seat < GameConfig.seats; seat++) {
        if (Pos.entryCell(seat) == i) ring = AppTheme.seat(seat);
      }
      _hole(canvas, g.trackCell(i), r,
          ring: ring, fill: ring == null ? null : Color.lerp(cream, ring, 0.55));
    }
  }

  void _drawHomeLanes(Canvas canvas) {
    for (var seat = 0; seat < GameConfig.seats; seat++) {
      final color = AppTheme.seat(seat);
      final first = g.homeCell(seat, 0);
      final last = g.homeCell(seat, GameConfig.homeSize - 1);
      canvas.drawLine(
          first,
          last,
          Paint()
            ..color = color.withValues(alpha: 0.22)
            ..strokeWidth = g.p * 0.9
            ..strokeCap = StrokeCap.round);
      for (var i = 0; i < GameConfig.homeSize; i++) {
        _hole(canvas, g.homeCell(seat, i), g.cellRadius,
            fill: Color.lerp(cream, color, 0.35));
      }
    }
  }

  void _drawPockets(Canvas canvas) {
    for (var seat = 0; seat < GameConfig.seats; seat++) {
      final color = AppTheme.seat(seat);
      final c = g.pocketCentre(seat);
      // Soft coloured glow marking the pocket.
      canvas.drawCircle(
          c,
          g.p * 1.5,
          Paint()
            ..color = color.withValues(alpha: 0.18)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.p * 0.7));
      canvas.drawCircle(
          c,
          g.p * 1.35,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = color.withValues(alpha: 0.45));
      for (var i = 0; i < GameConfig.marblesPerPlayer; i++) {
        _hole(canvas, g.baseCell(seat, i), g.cellRadius * 0.95);
      }
    }
  }

  void _drawCentre(Canvas canvas) {
    final inner = g.octagon(g.p * 3.3, corner: g.p * 0.2);
    canvas.drawPath(
        inner.shift(Offset(0, g.p * 0.1)),
        Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawPath(
      inner,
      Paint()
        ..shader = RadialGradient(
          colors: [cream, creamDark],
        ).createShader(Rect.fromCircle(center: g.centre, radius: g.p * 3.5)),
    );
    canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppTheme.goldDeep.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => old.g.size != g.size;
}
