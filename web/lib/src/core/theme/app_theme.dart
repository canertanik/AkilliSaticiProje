import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E9A78);
  static const Color primaryDark = Color(0xFF15795E);
  static const Color accent = Color(0xFF6C4CCF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color danger = Color(0xFFE74C3C);

  static const double radiusSm = 12;
  static const double radiusMd = 16;

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 22, offset: Offset(0, 10)),
  ];

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
    );

    final textTheme = base.textTheme.copyWith(
      headlineLarge: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
      headlineMedium: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
      headlineSmall: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      titleLarge: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      titleMedium: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      bodyLarge: const TextStyle(height: 1.4, color: Color(0xFF0F172A)),
      bodyMedium: const TextStyle(height: 1.4, color: Color(0xFF0F172A)),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
        floatingLabelStyle: TextStyle(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: const Color(0xFF374151), fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: const BorderSide(color: border),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }
}
