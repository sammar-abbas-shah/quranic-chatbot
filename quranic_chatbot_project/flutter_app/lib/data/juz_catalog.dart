part of '../main.dart';

// ---------------------------------------------------------------------------
// Built-in Juz (Para) start positions.
// ---------------------------------------------------------------------------

/// Standard Juz (Para) boundaries: the Surah/Ayah where each of the 30 Juz
/// begins, so the whole Quran can be read Juz-by-Juz instead of only
/// Surah-by-Surah. The end of a Juz is just before the next one's start
/// (Juz 30 runs to the very end of the Quran, 114:6).
class JuzCatalog {
  JuzCatalog._();

  static const int count = 30;

  /// (juz, startSurah, startAyah).
  static const List<(int, int, int)> _starts = [
    (1, 1, 1),
    (2, 2, 142),
    (3, 2, 253),
    (4, 3, 93),
    (5, 4, 24),
    (6, 4, 148),
    (7, 5, 82),
    (8, 6, 111),
    (9, 7, 88),
    (10, 8, 41),
    (11, 9, 93),
    (12, 11, 6),
    (13, 12, 53),
    (14, 15, 1),
    (15, 17, 1),
    (16, 18, 75),
    (17, 21, 1),
    (18, 23, 1),
    (19, 25, 21),
    (20, 27, 56),
    (21, 29, 46),
    (22, 33, 31),
    (23, 36, 28),
    (24, 39, 32),
    (25, 41, 47),
    (26, 46, 1),
    (27, 51, 31),
    (28, 58, 1),
    (29, 67, 1),
    (30, 78, 1),
  ];

  static (int surah, int ayah) startOf(int juz) {
    final e = _starts[(juz - 1).clamp(0, count - 1)];
    return (e.$2, e.$3);
  }

  /// Inclusive end (surah, ayah) -- the ayah right before the next Juz's
  /// start. Juz 30 ends at the last ayah of the Quran.
  static (int surah, int ayah) endOf(int juz) {
    if (juz >= count) return (114, 6);
    final next = startOf(juz + 1);
    if (next.$2 > 1) return (next.$1, next.$2 - 1);
    final prev = SurahCatalog.byNumber(next.$1 - 1);
    return (prev.number, prev.ayahCount);
  }

  /// True if (surah, ayah) falls within [juz]'s range, comparing by Quran
  /// order (surah number, then ayah number within it).
  static bool contains(int juz, int surah, int ayah) {
    final start = startOf(juz);
    final end = endOf(juz);
    bool afterOrAt(int s, int a, (int, int) p) =>
        s > p.$1 || (s == p.$1 && a >= p.$2);
    bool beforeOrAt(int s, int a, (int, int) p) =>
        s < p.$1 || (s == p.$1 && a <= p.$2);
    return afterOrAt(surah, ayah, start) && beforeOrAt(surah, ayah, end);
  }

  /// Short "Al-Fatihah 1:1 – Al-Baqarah 2:141" style subtitle for a Juz tile.
  static String rangeLabel(int juz) {
    final start = startOf(juz);
    final end = endOf(juz);
    final startName = SurahCatalog.byNumber(start.$1).englishName;
    final endName = SurahCatalog.byNumber(end.$1).englishName;
    final startRef = '$startName ${start.$1}:${start.$2}';
    if (start.$1 == end.$1 && start.$2 == end.$2) return startRef;
    return '$startRef – $endName ${end.$1}:${end.$2}';
  }
}
