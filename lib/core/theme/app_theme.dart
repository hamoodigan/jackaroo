import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single "midnight felt & gold" look. Seat colours are the classic
/// Jackaroo red / blue / green / yellow, tuned to glow on dark felt.
class AppTheme {
  AppTheme._();

  static const Color bgTop = Color(0xFF0E1A2B);
  static const Color bgBottom = Color(0xFF060B14);
  static const Color felt = Color(0xFF123B2E);
  static const Color feltDark = Color(0xFF0B2A20);
  static const Color wood = Color(0xFF5A3A1E);
  static const Color woodLight = Color(0xFF8B5A2B);
  static const Color gold = Color(0xFFE8C36A);
  static const Color goldDeep = Color(0xFFB8892F);
  static const Color ivory = Color(0xFFF7F1E3);
  static const Color surface = Color(0xFF16233A);
  static const Color surfaceHi = Color(0xFF1F3050);
  static const Color muted = Color(0xFF8A9BB8);

  static const List<Color> seatColors = [
    Color(0xFFE5484D), // red
    Color(0xFF3E8BFF), // blue
    Color(0xFF2FBF71), // green
    Color(0xFFF7C948), // yellow
  ];

  static const List<Color> seatDark = [
    Color(0xFF8E1E22),
    Color(0xFF1B4BA8),
    Color(0xFF14743F),
    Color(0xFFA97F0C),
  ];

  static Color seat(int i) => seatColors[i % 4];

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static TextStyle title(double size, {Color color = gold}) =>
      GoogleFonts.cinzelDecorative(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.5,
      );

  static TextStyle display(double size,
          {Color color = ivory, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.cinzel(fontSize: size, fontWeight: weight, color: color);

  static ThemeData get data {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: bgBottom,
        secondary: Color(0xFF2FBF71),
        surface: surface,
        onSurface: ivory,
      ),
      scaffoldBackgroundColor: bgBottom,
    );
    final text = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: ivory,
      displayColor: ivory,
    );
    return base.copyWith(
      textTheme: text,
      dividerColor: Colors.white12,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? bgBottom : muted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? gold : surfaceHi),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceHi,
        contentTextStyle: TextStyle(color: ivory),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
