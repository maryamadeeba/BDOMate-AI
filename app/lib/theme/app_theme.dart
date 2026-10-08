import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  BDOMate.AI — Design System
//  Palette: Deep Indigo  #0D1B2A  (darkest bg)
//          Midnight     #1A2744  (card bg)
//          Electric     #4F8EF7  (primary blue)
//          Cyan Spark   #00E5C8  (accent teal)
//          Amber Glow   #FFB347  (warning/warm)
//          Crimson      #FF5C6A  (error)
//          Success      #3DD68C  (green)
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  // ── Core Palette ─────────────────────────────────────────────
  static const Color primary = Color(0xFF4F8EF7);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF00E5C8);
  static const Color accent = Color(0xFF00E5C8);
  static const Color warning = Color(0xFFFFB347);
  static const Color error = Color(0xFFFF5C6A);
  static const Color success = Color(0xFF3DD68C);

  // ── Added Missing Aliases for Backward Compatibility ──────────
  static const Color teal = Color(0xFF00E5C8); // Mapped to secondary cyan/teal
  static const Color amber = Color(0xFFFFB347); // Mapped to warning amber
  static const Color rose = Color(0xFFFF5C6A); // Mapped to error crimson/rose
  static const Color violet = Color(
    0xFF7C3AED,
  ); // Standard vibrant purple for indicators

  // ── Surface Palette ───────────────────────────────────────────
  static const Color surface = Color(0xFFF0F4FF); // light bg
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF0D1B2A);
  static const Color darkCard = Color(0xFF1A2744);
  static const Color darkCardAlt = Color(0xFF1E2F52);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);

  // ── Gradient Stops ────────────────────────────────────────────
  static const Color gradientStart = Color(0xFF0D1B2A);
  static const Color gradientMid = Color(0xFF1A2F5E);
  static const Color gradientEnd = Color(0xFF1A3A6B);

  // ─────────────────────────────────────────────────────────────
  //  LIGHT THEME
  // ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surface,
      fontFamily: 'Nunito', // rounded, modern
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          fontFamily: 'Nunito',
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shadowColor: primary.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider.withOpacity(0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontFamily: 'Nunito'),
        hintStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontFamily: 'Nunito',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
        ),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontFamily: 'Nunito'),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondary,
          fontFamily: 'Nunito',
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          fontFamily: 'Nunito',
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          color: textSecondary,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  DARK THEME
  // ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: darkBg,
        error: error,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Nunito',
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Gradients
  // ─────────────────────────────────────────────────────────────
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [gradientStart, gradientMid, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get accentGradient => const LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF00E5C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get blueGradient => const LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF4F8EF7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get purpleGradient => const LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get sunsetGradient => const LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration get gradientDecoration =>
      BoxDecoration(gradient: primaryGradient);

  // ─────────────────────────────────────────────────────────────
  //  Shadows
  // ─────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primary.withOpacity(0.10),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primary.withOpacity(0.35),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get tealGlowShadow => [
    BoxShadow(
      color: secondary.withOpacity(0.35),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
