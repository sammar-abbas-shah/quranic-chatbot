part of '../main.dart';

// ---------------------------------------------------------------------------
// Text styles and fonts.
// ---------------------------------------------------------------------------

/// Typography per script/role. Uses the platform fonts so the app works
/// offline everywhere. To use Amiri / Noto Nastaliq later, add the font files
/// to pubspec.yaml and set `fontFamily` below.
class AppTypography {
  AppTypography._();

  static TextStyle arabicQuran({double size = 28, Color? color}) =>
      TextStyle(fontSize: size, height: 2.0, color: color);

  static TextStyle arabicUi({
    double size = 16,
    Color? color,
    FontWeight? weight,
  }) =>
      TextStyle(fontSize: size, height: 1.8, color: color, fontWeight: weight);

  static TextStyle urdu({double size = 18, Color? color, FontWeight? weight}) =>
      TextStyle(fontSize: size, height: 2.0, color: color, fontWeight: weight);

  static TextStyle english({
    double size = 15,
    Color? color,
    FontWeight? weight,
  }) =>
      TextStyle(fontSize: size, height: 1.5, color: color, fontWeight: weight);

  static TextStyle heading({double size = 22, Color? color}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle body({Color? color, double size = 15}) =>
      english(size: size, color: color);

  static TextStyle caption({Color? color}) =>
      TextStyle(fontSize: 12, height: 1.4, color: color);

  static TextStyle button() =>
      const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

  static TextStyle forLanguage(
    String code, {
    double size = 16,
    Color? color,
    FontWeight? weight,
  }) {
    switch (code) {
      case 'ur':
        return urdu(size: size, color: color, weight: weight);
      case 'ar':
        return arabicUi(size: size, color: color, weight: weight);
      default:
        return english(size: size, color: color, weight: weight);
    }
  }
}
