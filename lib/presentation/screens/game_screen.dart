import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/game_config.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/game_controller.dart';
import '../controllers/online_controller.dart';
import '../widgets/board_view.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/hand_view.dart';
import '../widgets/player_strip.dart';
import '../widgets/settings_sheet.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GameController>()) {
      // Hot restart on web lands here without a controller.
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.offAllNamed('/'));
      return const Scaffold(body: SizedBox.shrink());
    }
    final c = Get.find<GameController>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _menu(context, c);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.background),
          child: SafeArea(
            child: Stack(
              children: [
                OrientationBuilder(
                  builder: (ctx, o) => o == Orientation.landscape
                      ? _landscape(context, c)
                      : _portrait(context, c),
                ),
                Obx(() => c.phase.value == Phase.cover
                    ? _PassCover(c: c)
                    : const SizedBox.shrink()),
                Obx(() => c.phase.value == Phase.over
                    ? _GameOver(c: c)
                    : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, GameController c) => Row(
        children: [
          IconButton(
            onPressed: () => _menu(context, c),
            icon: const Icon(Icons.menu_rounded, color: AppTheme.gold),
          ),
          Expanded(
            child: Text('JACKAROO',
                textAlign: TextAlign.center,
                style: AppTheme.title(16, color: AppTheme.gold.withValues(alpha: 0.85))),
          ),
          IconButton(
            tooltip: 'cards_guide'.tr,
            onPressed: () => Get.toNamed('/cards'),
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.gold),
          ),
          IconButton(
            onPressed: () => SettingsSheet.show(context),
            icon: const Icon(Icons.tune_rounded, color: AppTheme.gold),
          ),
        ],
      );

  Widget _portrait(BuildContext context, GameController c) {
    return LayoutBuilder(builder: (ctx, cons) {
      final cardW = (cons.maxWidth / 7.2).clamp(46.0, 80.0);
      return Column(
        children: [
          _topBar(context, c),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: PlayerStrip(c: c),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: BoardView(c: c),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: HandView(c: c, cardWidth: cardW),
          ),
        ],
      );
    });
  }

  Widget _landscape(BuildContext context, GameController c) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: BoardView(c: c),
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _topBar(context, c),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: PlayerStrip(c: c, vertical: true),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(10),
                child: HandView(c: c, cardWidth: 56),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _menu(BuildContext context, GameController c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('menu'.tr, style: AppTheme.display(20, color: AppTheme.gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogButton('resume'.tr, Icons.play_arrow_rounded, () => Get.back()),
            _dialogButton('cards_guide'.tr, Icons.style_rounded, () {
              Get.back();
              Get.toNamed('/cards');
            }),
            if (!c.isOnline)
              _dialogButton('restart'.tr, Icons.refresh_rounded, () {
                Get.back();
                c.newGame();
              }),
            _dialogButton('quit'.tr, Icons.logout_rounded, () {
              Get.back();
              if (c.isOnline) Get.find<OnlineController>().leave(silent: true);
              Get.offAllNamed('/');
              Get.delete<GameController>(force: true);
            }),
          ],
        ),
      ),
    );
  }

  static Widget _dialogButton(String label, IconData icon, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: 240,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.surfaceHi,
              foregroundColor: AppTheme.ivory,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onTap,
            icon: Icon(icon, color: AppTheme.gold),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

/// Full-screen blur between two human turns so nobody peeks.
class _PassCover extends StatelessWidget {
  final GameController c;
  const _PassCover({required this.c});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.seat(c.turn);
    return Positioned.fill(
      child: GestureDetector(
        onTap: c.reveal,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            color: AppTheme.bgBottom.withValues(alpha: 0.75),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('pass_to'.tr,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 16)),
                const SizedBox(height: 14),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.4),
                      colors: [Color.lerp(color, Colors.white, 0.5)!, color, AppTheme.seatDark[c.turn]],
                    ),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 30)],
                  ),
                ),
                const SizedBox(height: 14),
                Text(c.current.name, style: AppTheme.display(30)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text('tap_to_reveal'.tr,
                      style: const TextStyle(
                          color: AppTheme.bgBottom, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOver extends StatelessWidget {
  final GameController c;
  const _GameOver({required this.c});

  @override
  Widget build(BuildContext context) {
    final team = c.winnerTeam.value ?? 0;
    final seats = [team, team + 2];
    return Positioned.fill(
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: AppTheme.bgBottom.withValues(alpha: 0.7)),
          ),
          const ConfettiOverlay(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(color: AppTheme.gold.withValues(alpha: 0.25), blurRadius: 40)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: AppTheme.gold, size: 54),
                    const SizedBox(height: 8),
                    Text('winner'.trParams({'team': c.teamName(team)}),
                        textAlign: TextAlign.center,
                        style: AppTheme.display(26, color: AppTheme.gold)),
                    const SizedBox(height: 6),
                    Text(seats.map((s) => c.players[s].name).join(' & '),
                        style: const TextStyle(color: AppTheme.ivory, fontSize: 16)),
                    const SizedBox(height: 18),
                    for (var s = 0; s < GameConfig.seats; s++) _statRow(s),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.ivory,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              if (c.isOnline) Get.find<OnlineController>().leave(silent: true);
                              Get.offAllNamed('/');
                              Get.delete<GameController>(force: true);
                            },
                            child: Text('main_menu'.tr),
                          ),
                        ),
                        if (!c.isOnline) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.gold,
                                foregroundColor: AppTheme.bgBottom,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: c.newGame,
                              child: Text('play_again'.tr,
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(int s) {
    final color = AppTheme.seat(s);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(c.players[s].name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          _stat('home_marbles'.tr, '${c.state.homeCount(s)}'),
          _stat('captures'.tr, '${c.state.captures[s]}'),
          _stat('moves'.tr, '${c.state.movesPlayed[s]}'),
        ],
      ),
    );
  }

  Widget _stat(String label, String v) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: Column(
          children: [
            Text(v, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.gold)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
          ],
        ),
      );
}
