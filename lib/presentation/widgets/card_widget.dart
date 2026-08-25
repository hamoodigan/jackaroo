import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/card.dart';

/// A playing card. [playable] cards glow, unplayable ones are dimmed,
/// the selected card lifts and gets a gold frame.
class CardWidget extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final bool playable;
  final bool selected;
  final bool faceDown;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.card,
    required this.width,
    this.playable = true,
    this.selected = false,
    this.faceDown = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = width * 1.42;
    final red = card.isRed;
    final ink = red ? const Color(0xFFC62828) : const Color(0xFF1B1F2A);
    final radius = BorderRadius.circular(width * 0.12);

    Widget face = Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF1ECE0)],
        ),
        border: Border.all(
          color: selected ? AppTheme.gold : Colors.black.withValues(alpha: 0.15),
          width: selected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: selected ? 16 : 8,
            offset: Offset(0, selected ? 8 : 4),
          ),
          if (playable && !selected)
            BoxShadow(
              color: AppTheme.gold.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: width * 0.08,
            top: width * 0.04,
            child: _corner(ink),
          ),
          Positioned(
            right: width * 0.08,
            bottom: width * 0.04,
            child: Transform.rotate(angle: 3.14159, child: _corner(ink)),
          ),
          Center(
            child: Text(
              card.suitSymbol,
              style: TextStyle(
                fontSize: width * 0.55,
                color: ink,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

    if (faceDown) {
      face = Container(
        width: width,
        height: h,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A5F), Color(0xFF0E1A2B)],
          ),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: width * 0.62,
            height: h * 0.72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.06),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text('J',
                  style: AppTheme.title(width * 0.32,
                      color: AppTheme.gold.withValues(alpha: 0.8))),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, selected ? -width * 0.35 : 0, 0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: playable || faceDown ? 1 : 0.45,
          child: face,
        ),
      ),
    );
  }

  Widget _corner(Color ink) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            card.rankLabel,
            style: TextStyle(
              fontSize: width * 0.26,
              fontWeight: FontWeight.w800,
              color: ink,
              height: 1,
              fontFamily: 'serif',
            ),
          ),
          Text(
            card.suitSymbol,
            style: TextStyle(fontSize: width * 0.2, color: ink, height: 1),
          ),
        ],
      );
}
