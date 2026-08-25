import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/move.dart';
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
      final seat = c.viewSeat;
      final myTurn = c.turn == seat && c.isLocalSeat(seat);
      final showFace = !hidden && (c.isOnline || !c.current.isBot);
      final hand = c.handOf(seat);
      final playable = myTurn ? c.playableCards : const <int>{};
      final discard = myTurn && c.mustDiscard;
      final sel = c.selectedCard.value;
      final color = AppTheme.seat(c.turn);
      final special = c.specialMove.value;
      final notice = c.notice.value;
      final victim = c.players[(c.turn + 1) % c.players.length].name;

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
          if (notice.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: cardWidth * 0.12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                ),
                child: Text(notice,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.gold, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          if (special != null && myTurn && !hidden)
            Padding(
              padding: EdgeInsets.only(top: cardWidth * 0.18),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.bgBottom,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: c.playSpecial,
                icon: Icon(special.kind == MoveKind.steal
                    ? Icons.back_hand_rounded
                    : Icons.block_rounded),
                label: Text(
                  (special.kind == MoveKind.steal ? 'queen_action' : 'ten_action')
                      .trParams({'name': victim}),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
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
                      onTap: showFace && myTurn ? () => c.tapCard(id) : null,
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
