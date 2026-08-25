import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/game_config.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/move.dart';
import '../../domain/entities/position.dart';
import '../controllers/game_controller.dart';
import 'board_geometry.dart';
import 'board_painter.dart';
import 'card_widget.dart';

/// The playable board: static painter underneath, animated marbles and
/// tappable target markers on top.
class BoardView extends StatelessWidget {
  final GameController c;
  const BoardView({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cons) {
      final size = cons.biggest.shortestSide;
      final g = BoardGeometry(size);
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _onTap(d.localPosition, g),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: BoardPainter(g),
                  ),
                ),
                // Last played card rests in the centre octagon, like the deck
                // on the real board.
                Obx(() {
                  final last = c.lastPlayed.value;
                  final w = g.p * 2.6;
                  return Positioned(
                    left: g.centre.dx - w / 2,
                    top: g.centre.dy - w * 1.42 / 2,
                    child: IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: last == null
                            ? SizedBox(width: w, height: w * 1.42)
                            : CardWidget(
                                key: ValueKey(last),
                                card: c.card(last),
                                width: w,
                              ),
                      ),
                    ),
                  );
                }),
                Obx(() {
                  c.tick.value; // subscribe
                  final phase = c.phase.value;
                  final ts = c.targets;
                  final hl = c.highlightMarbles;
                  final lm = c.lastMoved;
                  final sel = c.selectedMarble.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final t in ts) _TargetMarker(g: g, target: t, seat: t.seat),
                      for (var s = 0; s < GameConfig.seats; s++)
                        for (var i = 0; i < GameConfig.marblesPerPlayer; i++)
                          _Marble(
                            g: g,
                            ref: MarbleRef(s, i),
                            pos: c.displayPos[MarbleRef(s, i)] ?? Pos.base,
                            highlighted: hl.contains(MarbleRef(s, i)),
                            trail: lm.contains(MarbleRef(s, i)),
                            selected: sel == MarbleRef(s, i),
                            dim: phase == Phase.cover,
                          ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _onTap(Offset p, BoardGeometry g) {
    if (!c.selecting) return;
    // Marbles first (they may sit on target cells).
    MarbleRef? best;
    var bestD = g.marbleRadius * 1.6;
    for (final e in c.displayPos.entries) {
      final o = g.locate(e.key.seat, e.value, e.key.idx);
      final d = (o - p).distance;
      if (d < bestD) {
        bestD = d;
        best = e.key;
      }
    }
    if (best != null) {
      c.tapMarble(best);
      return;
    }
    Target? bt;
    var btD = g.marbleRadius * 1.8;
    for (final t in c.targets) {
      final o = g.locate(t.seat, t.pos, 0);
      final d = (o - p).distance;
      if (d < btD) {
        btD = d;
        bt = t;
      }
    }
    if (bt != null) c.tapTarget(bt);
  }
}

class _Marble extends StatelessWidget {
  final BoardGeometry g;
  final MarbleRef ref;
  final int pos;
  final bool highlighted;
  final bool selected;
  final bool dim;
  final bool trail;

  const _Marble({
    required this.g,
    required this.ref,
    required this.pos,
    required this.highlighted,
    required this.selected,
    required this.dim,
    this.trail = false,
  });

  @override
  Widget build(BuildContext context) {
    final o = g.locate(ref.seat, pos, ref.idx);
    final r = g.marbleRadius * (selected ? 1.18 : 1.0);
    final color = AppTheme.seat(ref.seat);
    return AnimatedPositioned(
      duration: GameConfig.marbleStep,
      curve: Curves.easeOut,
      left: o.dx - r,
      top: o.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dim ? 0.35 : 1,
          child: _MarbleBody(
              color: color,
              dark: AppTheme.seatDark[ref.seat],
              r: r,
              glow: highlighted || selected,
              trail: trail),
        ),
      ),
    );
  }
}

class _MarbleBody extends StatefulWidget {
  final Color color, dark;
  final double r;
  final bool glow;
  final bool trail;
  const _MarbleBody(
      {required this.color,
      required this.dark,
      required this.r,
      required this.glow,
      this.trail = false});

  @override
  State<_MarbleBody> createState() => _MarbleBodyState();
}

class _MarbleBodyState extends State<_MarbleBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) {
        final t = widget.glow || widget.trail ? _pulse.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.4, -0.45),
              radius: 0.9,
              colors: [
                Color.lerp(widget.color, Colors.white, 0.55)!,
                widget.color,
                widget.dark,
              ],
              stops: const [0, 0.45, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: r * 0.5,
                offset: Offset(0, r * 0.3),
              ),
              if (widget.trail && !widget.glow)
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.7 + 0.3 * t),
                  blurRadius: r * (0.9 + t * 0.6),
                  spreadRadius: r * (0.25 + t * 0.15),
                ),
              if (widget.glow)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.55 + 0.4 * t),
                  blurRadius: r * (0.8 + t * 0.8),
                  spreadRadius: r * (0.15 + t * 0.2),
                ),
            ],
            border: widget.glow
                ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: r * 0.14)
                : widget.trail
                    ? Border.all(color: AppTheme.gold, width: r * 0.16)
                    : null,
          ),
        );
      },
    );
  }
}

class _TargetMarker extends StatefulWidget {
  final BoardGeometry g;
  final Target target;
  final int seat;
  const _TargetMarker({required this.g, required this.target, required this.seat});

  @override
  State<_TargetMarker> createState() => _TargetMarkerState();
}

class _TargetMarkerState extends State<_TargetMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    final o = g.locate(widget.target.seat, widget.target.pos, 0);
    final r = g.marbleRadius * 1.5;
    return Positioned(
      left: o.dx - r,
      top: o.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final t = _c.value;
            return CustomPaint(
              painter: _RingPainter(t, AppTheme.seat(widget.seat)),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color color;
  _RingPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rMax = size.width / 2;
    canvas.drawCircle(
        c, rMax * 0.5, Paint()..color = AppTheme.gold.withValues(alpha: 0.35));
    canvas.drawCircle(
        c,
        rMax * 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppTheme.gold);
    canvas.drawCircle(
        c,
        rMax * (0.5 + 0.5 * t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppTheme.gold.withValues(alpha: 1 - t));
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.t != t;
}
