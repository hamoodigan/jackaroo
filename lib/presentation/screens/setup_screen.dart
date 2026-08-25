import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/player.dart';
import '../controllers/settings_controller.dart';
import '../controllers/setup_controller.dart';
import '../controllers/game_controller.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SetupController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.background),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      children: [
                        _sectionTitle('players'.tr),
                        const SizedBox(height: 8),
                        Obx(() => Column(
                              children: [
                                for (var s = 0; s < 4; s++)
                                  _SeatCard(seat: s, slot: c.players[s], c: c),
                              ],
                            )),
                        const SizedBox(height: 18),
                        _sectionTitle('house_rules'.tr),
                        const SizedBox(height: 8),
                        Obx(() {
                          final r = c.rules.value;
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                _rule('rule_jack_any', r.jackSwapAny,
                                    (v) => c.setRules(r.copyWith(jackSwapAny: v))),
                                _rule('rule_five_any', r.fiveMovesAny,
                                    (v) => c.setRules(r.copyWith(fiveMovesAny: v))),
                                _rule('rule_king_burns', r.kingBurnsPath,
                                    (v) => c.setRules(r.copyWith(kingBurnsPath: v))),
                                _rule('rule_burn_partner', r.canBurnPartner,
                                    (v) => c.setRules(r.copyWith(canBurnPartner: v))),
                                _rule('rule_seven_split', r.sevenSplit,
                                    (v) => c.setRules(r.copyWith(sevenSplit: v))),
                                _rule('rule_ten_skip', r.tenSkip,
                                    (v) => c.setRules(r.copyWith(tenSkip: v))),
                                _rule('rule_queen_steal', r.queenSteal,
                                    (v) => c.setRules(r.copyWith(queenSteal: v)),
                                    last: true),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                        _StartButton(onTap: () => _start(c)),
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

  void _start(SetupController c) {
    final players = c.finalPlayers();
    final settings = Get.find<SettingsController>();
    Get.delete<GameController>(force: true);
    Get.put(
      GameController(
        players: players,
        rules: c.rules.value,
        hideHands: settings.hideHands.value,
        audio: settings.audio,
      ),
      permanent: true,
    );
    Get.toNamed('/game');
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Row(
          children: [
            IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.gold),
            ),
            Text('setup_title'.tr, style: AppTheme.display(22, color: AppTheme.gold)),
          ],
        ),
      );

  Widget _sectionTitle(String t) => Text(
        t.toUpperCase(),
        style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w800),
      );

  Widget _rule(String key, bool value, ValueChanged<bool> onChanged, {bool last = false}) =>
      Column(
        children: [
          SwitchListTile(
            title: Text(key.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${key}_hint'.tr,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            value: value,
            onChanged: onChanged,
          ),
          if (!last) const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      );
}

class _SeatCard extends StatelessWidget {
  final int seat;
  final PlayerSlot slot;
  final SetupController c;
  const _SeatCard({required this.seat, required this.slot, required this.c});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.seat(seat);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.4),
                colors: [Color.lerp(color, Colors.white, 0.5)!, color, AppTheme.seatDark[seat]],
              ),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
            ),
            child: Center(
              child: Text(seat % 2 == 0 ? 'A' : 'B',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: ValueKey('name$seat'),
                  initialValue: slot.name,
                  decoration: InputDecoration(
                    hintText: 'name_hint'.tr,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  onChanged: (v) => c.setName(seat, v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Toggle(
                      options: ['human'.tr, 'bot'.tr],
                      selected: slot.isBot ? 1 : 0,
                      onChanged: (i) => c.toggleBot(seat, i == 1),
                    ),
                    const SizedBox(width: 8),
                    if (slot.isBot)
                      Expanded(
                        child: _Toggle(
                          options: ['easy'.tr, 'normal'.tr, 'hard'.tr],
                          selected: slot.level.index,
                          onChanged: (i) => c.setLevel(seat, BotLevel.values[i]),
                          compact: true,
                        ),
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

class _Toggle extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool compact;
  const _Toggle({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.bgBottom,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected == i ? AppTheme.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected == i ? AppTheme.bgBottom : AppTheme.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFFFFE08A), AppTheme.goldDeep]),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Center(
            child: Text(
              'start_game'.tr,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.bgBottom),
            ),
          ),
        ),
      ),
    );
  }
}
