part of '../main.dart';

// ---------------------------------------------------------------------------
// General helpers: script/direction detection, Arabic normalisation, date and duration formatting, LoadState.
// ---------------------------------------------------------------------------

// ============================================================== 6. UTILS

enum LoadState { loading, loaded, error, empty }

enum TextScript { latin, arabic, urdu }

final RegExp _urduOnly = RegExp('[ٹڈڑںےھگچپکیۓ۔]');
final RegExp _arabicChars = RegExp(r'[\u0600-\u06FF]');
final RegExp _latinChars = RegExp(r'[A-Za-z]');

/// Detects the dominant script so chat text uses the right style/direction.
TextScript detectScript(String text) {
  final arabic = _arabicChars.allMatches(text).length;
  final latin = _latinChars.allMatches(text).length;
  if (arabic == 0 || arabic < latin) return TextScript.latin;
  return _urduOnly.hasMatch(text) ? TextScript.urdu : TextScript.arabic;
}

TextDirection directionOf(String text) => detectScript(text) == TextScript.latin
    ? TextDirection.ltr
    : TextDirection.rtl;

TextStyle styleForScript(
  TextScript s, {
  double size = 16,
  Color? color,
  FontWeight? weight,
}) {
  switch (s) {
    case TextScript.urdu:
      return AppTypography.urdu(size: size, color: color, weight: weight);
    case TextScript.arabic:
      return AppTypography.arabicUi(size: size, color: color, weight: weight);
    case TextScript.latin:
      return AppTypography.english(size: size, color: color, weight: weight);
  }
}

final RegExp _diacritics = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

/// Removes diacritics and unifies alef/yeh forms for Arabic search matching.
String normalizeArabic(String s) => s
    .replaceAll(_diacritics, '')
    .replaceAll('ٱ', 'ا')
    .replaceAll('أ', 'ا')
    .replaceAll('إ', 'ا')
    .replaceAll('آ', 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه');

String formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String relativeDate(BuildContext context, DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return context.tr('today');
  if (diff == 1) return context.tr('yesterday');
  return '${_months[d.month - 1]} ${d.day}';
}

String localeIdFor(String languageCode) {
  switch (languageCode) {
    case 'ur':
      return 'ur-PK';
    case 'ar':
      return 'ar-SA';
    default:
      return 'en-US';
  }
}
