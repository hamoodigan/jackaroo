import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/game_controller.dart';
import 'card_widget.dart';

/// The current player's cards, fanned along the bottom, plus the status
/// line above them.
class HandView extends StatelessWidget {
  final GameController c;
  final double cardWidth;
  const HandView({super.key, required this.c, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      c.tick.value;
      final phase = c.phase.value;
      final hidden = phase == Phase.cover || phase == Phase.over;
      final showFace = !hidden && !c.current.isBot;
      final hand = c.handOf(c.turn);
      final playable = c.playableCards;
      final discard = c.mustDiscard;
      final sel = c.selectedCard.value;
      final color = AppTheme.seat(c.turn);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Row(
              key: ValueKey(c.message.value + phase.name),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (phase != Phase.cover)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [BoxShadow(color: color, blurRadius: 8)],
                    ),
                  ),
                Flexible(
                  child: Text(
                    phase == Phase.cover ? '' : c.message.value,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: discard && !hidden ? const Color(0xFFFFB4A8) : AppTheme.ivory,
                      fontWeight: FontWeight.w700,
                      fontSize: cardWidth * 0.22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: cardWidth * 0.3),
          SizedBox(
            height: cardWidth * 1.42 + cardWidth * 0.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final id in hand)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.06),
                    child: CardWidget(
                      card: c.card(id),
                      width: cardWidth,
                      faceDown: !showFace,
                      playable: showFace && (discard || playable.contains(id)),
                      selected: sel == id,
                      onTap: showFace ? () => c.tapCard(id) : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
