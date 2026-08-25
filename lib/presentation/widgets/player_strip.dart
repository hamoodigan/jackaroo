import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/game_config.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/game_controller.dart';
import 'card_widget.dart';

/// Four compact player chips (teams paired by colour bar) plus the
/// last-played card and round counter.
class PlayerStrip extends StatelessWidget {
  final GameController c;
  final bool vertical;
  const PlayerStrip({super.key, required this.c, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      c.tick.value;
      final chips = [
        for (var s = 0; s < GameConfig.seats; s++) _chip(context, s),
      ];
      final centre = _centre(context);
      if (vertical) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            centre,
            const SizedBox(height: 8),
            ...chips.map((w) => Padding(padding: const EdgeInsets.only(bottom: 6), child: w)),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: chips[1]),
          const SizedBox(width: 6),
          Expanded(child: chips[2]),
          const SizedBox(width: 6),
          centre,
          const SizedBox(width: 6),
          Expanded(child: chips[3]),
          const SizedBox(width: 6),
          Expanded(child: chips[0]),
        ],
      );
    });
  }

  Widget _centre(BuildContext context) {
    final last = c.lastPlayed.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (last != null)
          CardWidget(card: c.card(last), width: 26)
        else
          Container(
            width: 26,
            height: 37,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24),
            ),
          ),
        const SizedBox(height: 3),
        Text('round'.trParams({'n': '${c.state.round}'}),
            style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
      ],
    );
  }

  Widget _chip(BuildContext context, int seat) {
    final p = c.players[seat];
    final color = AppTheme.seat(seat);
    final active = c.turn == seat && c.phase.value != Phase.over;
    final home = c.state.homeCount(seat);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.22) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? color : Colors.white10,
          width: active ? 1.5 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.4),
                colors: [Color.lerp(color, Colors.white, 0.5)!, color, AppTheme.seatDark[seat]],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppTheme.ivory,
                  ),
                ),
                Row(
                  children: [
                    Icon(p.isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
                        size: 10, color: AppTheme.muted),
                    const SizedBox(width: 3),
                    Text(
                      '$home/${GameConfig.marblesPerPlayer}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      seat % 2 == 0 ? 'A' : 'B',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.gold.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
