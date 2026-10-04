part of '../main.dart';

// ---------------------------------------------------------------------------
// Colour tokens.
// ---------------------------------------------------------------------------

// ============================================================== 8. THEME

/// Centralised colour palette. Deep green + warm cream + subtle gold.
class AppColors {
  AppColors._();

  // Brand
  static const Color deepGreen = Color(0xFF14613F);
  static const Color darkGreen = Color(0xFF0B3B2A);
  static const Color gold = Color(0xFFB58E3E);
  static const Color goldSoft = Color(0xFFD9BC7A);

  // Light theme
  static const Color cream = Color(0xFFFAF6EC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1B2620);
  static const Color textMuted = Color(0xFF5F6B65);
  static const Color lightBorder = Color(0xFFE6E0D0);

  // Dark theme (layered: bg < surface < surfaceHigh)
  static const Color darkBg = Color(0xFF0A110E);
  static const Color darkSurface = Color(0xFF121D18);
  static const Color darkSurfaceHigh = Color(0xFF1A2822);
  static const Color darkBorder = Color(0xFF25372F);
  static const Color darkText = Color(0xFFEAF0EB);
  static const Color darkMuted = Color(0xFF9AA9A1);
  static const Color mint = Color(0xFF6FCB9C);

  static const Color error = Color(0xFFB3261E);
  static const Color errorDark = Color(0xFFF2B8B5);
}
