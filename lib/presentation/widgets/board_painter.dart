import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/game_config.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/position.dart';
import 'board_geometry.dart';

/// Static board art: wooden frame, felt, holes, coloured entry cells,
/// home lanes, base plates and the centre medallion. Cached by Flutter
/// because nothing here changes between frames.
class BoardPainter extends CustomPainter {
  final BoardGeometry g;
  final String title;
  BoardPainter(this.g, this.title);

  @override
  void paint(Canvas canvas, Size size) {
    final s = g.size;
    final rect = Offset.zero & Size(s, s);
    final frame = g.crossPath(g.d * 1.25, g.d * 0.9);
    final felt = g.crossPath(g.d * 0.85, g.d * 0.7);

    // Drop shadow + wooden frame.
    canvas.drawPath(
        frame.shift(Offset(0, g.d * 0.25)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.d * 0.5));
    canvas.drawPath(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.woodLight, AppTheme.wood, Color(0xFF3E2814)],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipPath(frame);
    final grain = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var i = 0; i < 24; i++) {
      final y = s * (i / 24) + (i % 3) * 2.0;
      canvas.drawLine(Offset(0, y), Offset(s, y + s * 0.02), grain);
    }
    canvas.restore();
    canvas.drawPath(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppTheme.gold.withValues(alpha: 0.55),
    );

    // Felt.
    canvas.drawPath(
      felt,
      Paint()
        ..shader = RadialGradient(
          radius: 0.75,
          colors: [AppTheme.felt, AppTheme.feltDark],
        ).createShader(rect),
    );
    canvas.drawPath(
      felt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withValues(alpha: 0.35),
    );

    _drawBasePlates(canvas);
    _drawHomeLanes(canvas);
    _drawTrack(canvas);
    _drawCentre(canvas);
  }

  void _hole(Canvas canvas, Offset c, double r,
      {Color? ring, Color fill = const Color(0xFF0A1F18)}) {
    canvas.drawCircle(
        c.translate(0, r * 0.18),
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    canvas.drawCircle(c, r, Paint()..color = fill);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.22
          ..color = (ring ?? Colors.white).withValues(alpha: ring == null ? 0.10 : 0.9));
  }

  void _drawTrack(Canvas canvas) {
    final r = g.cellRadius;
    for (var i = 0; i < GameConfig.trackLength; i++) {
      final c = g.trackCell(i);
      Color? ring;
      for (var seat = 0; seat < 4; seat++) {
        if (Pos.entryCell(seat) == i) ring = AppTheme.seat(seat);
      }
      if (ring != null) {
        // Glow under the entry cell.
        canvas.drawCircle(
            c,
            r * 1.9,
            Paint()
              ..color = ring.withValues(alpha: 0.28)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9));
      }
      _hole(canvas, c, r, ring: ring);
    }
    // Direction arrows near each entry.
    for (var seat = 0; seat < 4; seat++) {
      final a = g.trackCell(Pos.abs(seat, 2));
      final b = g.trackCell(Pos.abs(seat, 3));
      final dir = (b - a) / (b - a).distance;
      final mid = a + dir * (g.d * 0.5);
      _arrow(canvas, mid, dir, g.d * 0.28, AppTheme.seat(seat).withValues(alpha: 0.7));
    }
  }

  void _arrow(Canvas canvas, Offset at, Offset dir, double len, Color color) {
    final n = Offset(-dir.dy, dir.dx);
    final tip = at + dir * len;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((at + n * len * 0.7).dx, (at + n * len * 0.7).dy)
      ..lineTo((at - n * len * 0.7).dx, (at - n * len * 0.7).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawHomeLanes(Canvas canvas) {
    for (var seat = 0; seat < 4; seat++) {
      final color = AppTheme.seat(seat);
      final first = g.homeCell(seat, 0);
      final last = g.homeCell(seat, GameConfig.homeSize - 1);
      final lane = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = g.d * 0.95
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(first, last, lane);
      for (var i = 0; i < GameConfig.homeSize; i++) {
        _hole(canvas, g.homeCell(seat, i), g.cellRadius,
            ring: color.withValues(alpha: 0.75),
            fill: AppTheme.seatDark[seat].withValues(alpha: 0.55));
      }
    }
  }

  void _drawBasePlates(Canvas canvas) {
    for (var seat = 0; seat < 4; seat++) {
      final color = AppTheme.seat(seat);
      final pts = List.generate(4, (i) => g.baseCell(seat, i));
      final cx = pts.map((p) => p.dx).reduce((a, b) => a + b) / 4;
      final cy = pts.map((p) => p.dy).reduce((a, b) => a + b) / 4;
      final plate = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: g.d * 2.5, height: g.d * 2.5),
        Radius.circular(g.d * 0.6),
      );
      canvas.drawRRect(
          plate,
          Paint()
            ..color = color.withValues(alpha: 0.30)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.d * 0.5));
      canvas.drawRRect(
          plate,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.45), AppTheme.seatDark[seat].withValues(alpha: 0.55)],
            ).createShader(plate.outerRect));
      canvas.drawRRect(
          plate,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = color.withValues(alpha: 0.8));
      for (final p in pts) {
        _hole(canvas, p, g.cellRadius * 0.95, fill: const Color(0xFF071612));
      }
    }
  }

  void _drawCentre(Canvas canvas) {
    final c = g.centre;
    final r = g.d * 2.1;
    canvas.drawCircle(
        c,
        r * 1.25,
        Paint()
          ..color = AppTheme.gold.withValues(alpha: 0.08)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppTheme.gold.withValues(alpha: 0.45));
    canvas.drawCircle(
        c,
        r * 0.86,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = AppTheme.gold.withValues(alpha: 0.3));
    // Compass-like spokes.
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final p1 = c + Offset(math.cos(a), math.sin(a)) * (r * 0.86);
      final p2 = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawLine(
          p1, p2, Paint()..color = AppTheme.gold.withValues(alpha: 0.5));
    }
    final tp = TextPainter(
      text: TextSpan(
        text: title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.gold.withValues(alpha: 0.85),
          fontSize: r * 0.28,
          letterSpacing: r * 0.06,
          fontWeight: FontWeight.w700,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.g.size != g.size || old.title != title;
}
