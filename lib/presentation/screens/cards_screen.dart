import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/card.dart';
import '../widgets/card_widget.dart';

/// One-screen reference: every rank with what it does. Opened from the
/// home menu, the in-game top bar and the pause menu.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  static const _ranks = [1, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2];
  static const _suits = [0, 1, 2, 3]; // spades, hearts, diamonds, clubs

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.background),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.gold),
                    ),
                    Text('cards_guide'.tr, style: AppTheme.display(22, color: AppTheme.gold)),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      itemCount: _ranks.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _ranks.length) return _footer();
                        final rank = _ranks[i];
                        final id = _suits[i % 4] * 13 + rank - 1;
                        return _row(PlayingCard(id), 'card_$rank'.tr);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(PlayingCard card, String text) {
    final special = const {1, 13, 11, 7, 5, 4}.contains(card.rank);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: special ? AppTheme.gold.withValues(alpha: 0.45) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          CardWidget(card: card, width: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.45, fontSize: 14.5, color: AppTheme.ivory),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_rounded, color: AppTheme.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('cards_footer'.tr,
                  style: const TextStyle(height: 1.45, fontSize: 13.5, color: AppTheme.ivory)),
            ),
          ],
        ),
      );
}
