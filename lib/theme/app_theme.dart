import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Earthy Premium Dark ─────────────────────────────────────────────────────
  // Backgrounds — warm forest, clearly stepped so cards pop
  static const Color bgPrimary    = Color(0xFF080E08); // deep forest floor
  static const Color bgSecondary  = Color(0xFF0F1C10); // mossy dark
  static const Color bgCard       = Color(0xFF152218); // rich earth
  static const Color bgCardHover  = Color(0xFF1C2E1E); // hovered card
  static const Color bgElevated   = Color(0xFF1E3322); // elevated surface

  // Primary — vivid lime-green (pops on warm dark, not a flat template green)
  static const Color primary      = Color(0xFF4ADE80);
  static const Color primaryDark  = Color(0xFF16A34A);
  static const Color primaryLight = Color(0xFF86EFAC);
  static const Color primarySubtle= Color(0x1A4ADE80);

  // Accent — sunset orange (sunlight + trees = planting story)
  static const Color accent   = Color(0xFFF97316);
  static const Color accentSoft = Color(0x33F97316);

  // Semantic
  static const Color danger  = Color(0xFFFF6B6B);
  static const Color info    = Color(0xFF60A5FA);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF97316);

  // Text — warm cream hierarchy, readable on warm dark backgrounds
  static const Color textPrimary   = Color(0xFFF7FEF0); // warm cream
  static const Color textSecondary = Color(0xFFB0D4BC); // sage-green mid
  static const Color textMuted     = Color(0xFF7DA98A); // muted sage

  // Borders
  static const Color border       = Color(0x264ADE80);
  static const Color borderStrong = Color(0x4D4ADE80);
  static const Color divider      = Color(0x12FFFFFF);

  // Gradients
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientAccent = LinearGradient(
    colors: [Color(0xFFEA580C), accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w800, color: textPrimary),
        displayMedium: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w700, color: textPrimary),
        headlineLarge: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgSecondary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: textMuted),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSecondary,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
