import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OpenParental design tokens. Warm neutrals + a calm guardian teal; status
/// hues are reserved and deliberately distinct from the brand color.
class AppColors {
  // Brand
  static const brand = Color(0xFF115E59); // deep teal (light)
  static const brandDark = Color(0xFF5FC9B9); // lifted teal (dark)

  // Warm neutrals — light
  static const surfaceLight = Color(0xFFFAF8F5);
  static const cardLight = Color(0xFFFFFFFF);
  static const inkLight = Color(0xFF1A1714);
  static const mutedLight = Color(0xFF6B635B);
  static const lineLight = Color(0xFFEBE5DD);

  // Warm neutrals — dark
  static const surfaceDark = Color(0xFF15120F);
  static const cardDark = Color(0xFF211C18);
  static const inkDark = Color(0xFFF2ECE5);
  static const mutedDark = Color(0xFFA39A90);
  static const lineDark = Color(0xFF2E2823);

  // Status (shared)
  static const online = Color(0xFF2E9E6B);
  static const attention = Color(0xFFC98A2B);
  static const alert = Color(0xFFC0492F);
  static const offline = Color(0xFF8A817A);
}

class AppRadius {
  static const card = 20.0;
  static const field = 14.0;
  static const chip = 999.0;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isLight = b == Brightness.light;
    final brand = isLight ? AppColors.brand : AppColors.brandDark;
    final surface = isLight ? AppColors.surfaceLight : AppColors.surfaceDark;
    final card = isLight ? AppColors.cardLight : AppColors.cardDark;
    final ink = isLight ? AppColors.inkLight : AppColors.inkDark;
    final muted = isLight ? AppColors.mutedLight : AppColors.mutedDark;
    final line = isLight ? AppColors.lineLight : AppColors.lineDark;

    final scheme = ColorScheme(
      brightness: b,
      primary: brand,
      onPrimary: isLight ? Colors.white : const Color(0xFF06302C),
      primaryContainer: brand.withValues(alpha: isLight ? 0.10 : 0.22),
      onPrimaryContainer: brand,
      secondary: AppColors.attention,
      onSecondary: Colors.white,
      error: AppColors.alert,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: card,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: line,
    );

    final base = isLight ? ThemeData.light() : ThemeData.dark();
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: line),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(54),
          textStyle: text.labelLarge?.copyWith(fontSize: 15.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: line),
          textStyle: text.labelLarge?.copyWith(fontSize: 15.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFF3EFEA) : const Color(0xFF1B1714),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: brand, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.inkLight : AppColors.cardDark,
        contentTextStyle: TextStyle(color: isLight ? Colors.white : ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
    );
  }
}
