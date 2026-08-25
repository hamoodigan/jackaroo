import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Dependency-free confetti: ~100 pieces falling with sway and spin.
class ConfettiOverlay extends StatefulWidget {
  final Duration duration;
  const ConfettiOverlay({super.key, this.duration = const Duration(milliseconds: 3500)});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => _c.isCompleted
            ? const SizedBox.shrink()
            : CustomPaint(size: Size.infinite, painter: _Painter(_c.value)),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final double t;
  _Painter(this.t);

  static final _palette = [
    ...AppTheme.seatColors,
    AppTheme.gold,
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final fade = t > 0.8 ? (1 - t) / 0.2 : 1.0;
    for (var i = 0; i < 100; i++) {
      final rnd = Random(i * 7919);
      final x0 = rnd.nextDouble();
      final speed = 0.7 + rnd.nextDouble() * 0.9;
      final delay = rnd.nextDouble() * 0.25;
      final sway = 0.02 + rnd.nextDouble() * 0.05;
      final swayFreq = 3 + rnd.nextDouble() * 4;
      final spin = (rnd.nextDouble() - 0.5) * 12;
      final w = 6 + rnd.nextDouble() * 6;
      final h = 3 + rnd.nextDouble() * 4;
      final color = _palette[i % _palette.length];
      final tt = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (tt <= 0) continue;
      final y = tt * tt * 0.35 + tt * speed;
      if (y > 1.15) continue;
      final x = x0 + sin(tt * swayFreq * pi) * sway;
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(tt * spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            const Radius.circular(1.5)),
        Paint()..color = color.withValues(alpha: 0.95 * fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => old.t != t;
}
