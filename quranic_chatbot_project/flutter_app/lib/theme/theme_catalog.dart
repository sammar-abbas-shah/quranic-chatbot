part of '../main.dart';

// ---------------------------------------------------------------------------
// The 12 selectable themes.
// ---------------------------------------------------------------------------

/// One full named color theme -- background, surfaces, text and accent
/// colors. AppTheme._build() turns one of these into a ThemeData; the
/// Settings screen shows [swatchBg]/[swatchAccent] as a little preview
/// circle for each entry in AppThemeCatalog.all.
class AppThemeSpec {
  const AppThemeSpec({
    required this.id,
    required this.nameKey,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.error,
  });

  final String id;

  /// Key into S.t() for the display name shown in Settings.
  final String nameKey;
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color border;

  /// Main accent used for buttons, active nav items, links.
  final Color primary;
  final Color onPrimary;

  /// Secondary accent (matches the app's former "gold" role: highlights,
  /// the Arabic/verse accent color).
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final Color error;

  Color get swatchBg => background;
  Color get swatchAccent => primary;
}

/// Every color theme the app offers: the two original green/gold "Classic"
/// looks, a Pink & White combo, and a handful of the most recognizable
/// Monkeytype community themes (Serika Dark is Monkeytype's own default,
/// then Dracula, Nord, Gruvbox, Catppuccin Mocha and Solarized Dark --
/// consistently among the most-used typing themes), reproduced here with
/// their well-known palettes.
class AppThemeCatalog {
  AppThemeCatalog._();

  static const classicLight = AppThemeSpec(
    id: 'classicLight',
    nameKey: 'themeClassicLight',
    brightness: Brightness.light,
    background: AppColors.cream,
    surface: AppColors.white,
    surfaceHigh: AppColors.white,
    border: AppColors.lightBorder,
    primary: AppColors.deepGreen,
    onPrimary: Colors.white,
    accent: AppColors.gold,
    textPrimary: AppColors.textDark,
    textMuted: AppColors.textMuted,
    error: AppColors.error,
  );

  static const classicDark = AppThemeSpec(
    id: 'classicDark',
    nameKey: 'themeClassicDark',
    brightness: Brightness.dark,
    background: AppColors.darkBg,
    surface: AppColors.darkSurface,
    surfaceHigh: AppColors.darkSurfaceHigh,
    border: AppColors.darkBorder,
    primary: AppColors.mint,
    onPrimary: AppColors.darkBg,
    accent: AppColors.goldSoft,
    textPrimary: AppColors.darkText,
    textMuted: AppColors.darkMuted,
    error: AppColors.errorDark,
  );

  /// Pink & white combo, as requested: soft rose accent on a warm white.
  static const blossom = AppThemeSpec(
    id: 'blossom',
    nameKey: 'themeBlossom',
    brightness: Brightness.light,
    background: Color(0xFFFFF6F8),
    surface: Colors.white,
    surfaceHigh: Colors.white,
    border: Color(0xFFF3D9E1),
    primary: Color(0xFFE0658C),
    onPrimary: Colors.white,
    accent: Color(0xFFC98AA8),
    textPrimary: Color(0xFF3A2530),
    textMuted: Color(0xFF8C7480),
    error: Color(0xFFB3261E),
  );

  /// Monkeytype's own default theme -- almost certainly its most-used one.
  static const serikaDark = AppThemeSpec(
    id: 'serikaDark',
    nameKey: 'themeSerikaDark',
    brightness: Brightness.dark,
    background: Color(0xFF323437),
    surface: Color(0xFF3B3E42),
    surfaceHigh: Color(0xFF44474B),
    border: Color(0xFF4A4D51),
    primary: Color(0xFFE2B714),
    onPrimary: Color(0xFF2C2E31),
    accent: Color(0xFFE2B714),
    textPrimary: Color(0xFFD1D0C5),
    textMuted: Color(0xFF8B8D91),
    error: Color(0xFFCA4754),
  );

  static const dracula = AppThemeSpec(
    id: 'dracula',
    nameKey: 'themeDracula',
    brightness: Brightness.dark,
    background: Color(0xFF282A36),
    surface: Color(0xFF2F3241),
    surfaceHigh: Color(0xFF44475A),
    border: Color(0xFF44475A),
    primary: Color(0xFFBD93F9),
    onPrimary: Color(0xFF1E1F29),
    accent: Color(0xFFFF79C6),
    textPrimary: Color(0xFFF8F8F2),
    textMuted: Color(0xFF9CA3C4),
    error: Color(0xFFFF5555),
  );

  static const nord = AppThemeSpec(
    id: 'nord',
    nameKey: 'themeNord',
    brightness: Brightness.dark,
    background: Color(0xFF2E3440),
    surface: Color(0xFF3B4252),
    surfaceHigh: Color(0xFF434C5E),
    border: Color(0xFF4C566A),
    primary: Color(0xFF88C0D0),
    onPrimary: Color(0xFF1F242D),
    accent: Color(0xFF8FBCBB),
    textPrimary: Color(0xFFE5E9F0),
    textMuted: Color(0xFFB0B8C4),
    error: Color(0xFFBF616A),
  );

  static const gruvbox = AppThemeSpec(
    id: 'gruvbox',
    nameKey: 'themeGruvbox',
    brightness: Brightness.dark,
    background: Color(0xFF282828),
    surface: Color(0xFF32302F),
    surfaceHigh: Color(0xFF3C3836),
    border: Color(0xFF4A4542),
    primary: Color(0xFFFABD2F),
    onPrimary: Color(0xFF282828),
    accent: Color(0xFFFE8019),
    textPrimary: Color(0xFFEBDBB2),
    textMuted: Color(0xFFA89984),
    error: Color(0xFFFB4934),
  );

  static const catppuccinMocha = AppThemeSpec(
    id: 'catppuccinMocha',
    nameKey: 'themeCatppuccin',
    brightness: Brightness.dark,
    background: Color(0xFF1E1E2E),
    surface: Color(0xFF262638),
    surfaceHigh: Color(0xFF313244),
    border: Color(0xFF45475A),
    primary: Color(0xFFCBA6F7),
    onPrimary: Color(0xFF1E1E2E),
    accent: Color(0xFFF5C2E7),
    textPrimary: Color(0xFFCDD6F4),
    textMuted: Color(0xFFA6ADC8),
    error: Color(0xFFF38BA8),
  );

  static const solarizedDark = AppThemeSpec(
    id: 'solarizedDark',
    nameKey: 'themeSolarized',
    brightness: Brightness.dark,
    background: Color(0xFF002B36),
    surface: Color(0xFF073642),
    surfaceHigh: Color(0xFF0A4351),
    border: Color(0xFF0E4B59),
    primary: Color(0xFF2AA198),
    onPrimary: Color(0xFF002B36),
    accent: Color(0xFFB58900),
    textPrimary: Color(0xFF93A1A1),
    textMuted: Color(0xFF6E8A8E),
    error: Color(0xFFDC322F),
  );

  static const monokai = AppThemeSpec(
    id: 'monokai',
    nameKey: 'themeMonokai',
    brightness: Brightness.dark,
    background: Color(0xFF272822),
    surface: Color(0xFF2F3129),
    surfaceHigh: Color(0xFF3E3D32),
    border: Color(0xFF49483E),
    primary: Color(0xFFA6E22E),
    onPrimary: Color(0xFF272822),
    accent: Color(0xFFF92672),
    textPrimary: Color(0xFFF8F8F2),
    textMuted: Color(0xFF9D9C8F),
    error: Color(0xFFF92672),
  );

  static const tokyoNight = AppThemeSpec(
    id: 'tokyoNight',
    nameKey: 'themeTokyoNight',
    brightness: Brightness.dark,
    background: Color(0xFF1A1B26),
    surface: Color(0xFF1F2335),
    surfaceHigh: Color(0xFF24283B),
    border: Color(0xFF2F3549),
    primary: Color(0xFF7AA2F7),
    onPrimary: Color(0xFF1A1B26),
    accent: Color(0xFFBB9AF7),
    textPrimary: Color(0xFFC0CAF5),
    textMuted: Color(0xFF8189B0),
    error: Color(0xFFF7768E),
  );

  static const rosePine = AppThemeSpec(
    id: 'rosePine',
    nameKey: 'themeRosePine',
    brightness: Brightness.dark,
    background: Color(0xFF191724),
    surface: Color(0xFF1F1D2E),
    surfaceHigh: Color(0xFF26233A),
    border: Color(0xFF403D52),
    primary: Color(0xFFC4A7E7),
    onPrimary: Color(0xFF191724),
    accent: Color(0xFFEBBCBA),
    textPrimary: Color(0xFFE0DEF4),
    textMuted: Color(0xFF908CAA),
    error: Color(0xFFEB6F92),
  );

  static const List<AppThemeSpec> all = [
    classicLight,
    classicDark,
    blossom,
    serikaDark,
    dracula,
    nord,
    gruvbox,
    catppuccinMocha,
    solarizedDark,
    monokai,
    tokyoNight,
    rosePine,
  ];

  static AppThemeSpec byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => classicLight);
}
