import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/settings_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.background),
        child: Stack(
          children: [
            const Positioned.fill(child: _FloatingMarbles()),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Logo(),
                        const SizedBox(height: 10),
                        Text(
                          'tagline'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.muted, fontSize: 15, letterSpacing: 1),
                        ),
                        const SizedBox(height: 48),
                        _MenuButton(
                          label: 'play'.tr,
                          icon: Icons.play_arrow_rounded,
                          primary: true,
                          onTap: () => Get.toNamed('/setup'),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: 'play_online'.tr,
                          icon: Icons.wifi_rounded,
                          onTap: () => Get.toNamed('/online'),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: 'cards_guide'.tr,
                          icon: Icons.style_rounded,
                          onTap: () => Get.toNamed('/cards'),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: 'how_to_play'.tr,
                          icon: Icons.menu_book_rounded,
                          onTap: () => Get.toNamed('/rules'),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: 'settings'.tr,
                          icon: Icons.tune_rounded,
                          onTap: () => SettingsSheet.show(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.4),
                    colors: [
                      Color.lerp(AppTheme.seat(i), Colors.white, 0.5)!,
                      AppTheme.seat(i),
                      AppTheme.seatDark[i],
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTheme.seat(i).withValues(alpha: 0.5), blurRadius: 10)
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [Color(0xFFFFE9A8), AppTheme.gold, AppTheme.goldDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(r),
          child: Text(
            'JACKAROO',
            textAlign: TextAlign.center,
            style: AppTheme.title(38, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

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
            gradient: primary
                ? const LinearGradient(colors: [Color(0xFFFFE08A), AppTheme.goldDeep])
                : null,
            color: primary ? null : AppTheme.surface,
            border: Border.all(
              color: primary ? Colors.transparent : AppTheme.gold.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: (primary ? AppTheme.gold : Colors.black).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primary ? AppTheme.bgBottom : AppTheme.gold, size: 26),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primary ? AppTheme.bgBottom : AppTheme.ivory,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slowly drifting, blurred marbles behind the menu.
class _FloatingMarbles extends StatefulWidget {
  const _FloatingMarbles();

  @override
  State<_FloatingMarbles> createState() => _FloatingMarblesState();
}

class _FloatingMarblesState extends State<_FloatingMarbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(painter: _DriftPainter(_c.value)),
    );
  }
}

class _DriftPainter extends CustomPainter {
  final double t;
  _DriftPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 14; i++) {
      final rnd = math.Random(i * 131);
      final x = rnd.nextDouble();
      final y0 = rnd.nextDouble();
      final r = 18 + rnd.nextDouble() * 40;
      final y = (y0 + t * (0.05 + rnd.nextDouble() * 0.08)) % 1.2 - 0.1;
      final c = AppTheme.seat(i % 4).withValues(alpha: 0.10);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        r,
        Paint()
          ..color = c
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DriftPainter old) => old.t != t;
}
