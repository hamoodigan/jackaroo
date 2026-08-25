import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/card.dart';
import '../widgets/card_widget.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = 'rules_body'.tr.trim();
    final blocks = body.split('\n\n');
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
                    Text('rules_title'.tr,
                        style: AppTheme.display(22, color: AppTheme.gold)),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      children: [
                        SizedBox(
                          height: 90,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final id in [0, 12 + 13, 10 + 26, 6 + 39, 3])
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: CardWidget(card: PlayingCard(id), width: 52),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (final b in blocks) _block(b),
                      ],
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

  Widget _block(String b) {
    final lines = b.trim().split('\n');
    final heading = lines.first;
    final rest = lines.skip(1).join('\n');
    final isHeading = heading.length < 20 && rest.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHeading) ...[
            Text(heading,
                style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 13)),
            const SizedBox(height: 8),
          ],
          Text(isHeading ? rest : b,
              style: const TextStyle(height: 1.5, fontSize: 15, color: AppTheme.ivory)),
        ],
      ),
    );
  }
}
