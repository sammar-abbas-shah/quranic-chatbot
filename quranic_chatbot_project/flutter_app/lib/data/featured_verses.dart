part of '../main.dart';

// ---------------------------------------------------------------------------
// Verses rotated on the Home screen.
// ---------------------------------------------------------------------------

/// A curated set of well-known, short/uplifting verses used to rotate the
/// Home screen's "Featured Verse" card so it isn't the same verse every
/// time the app is opened. Only surah/ayah numbers are listed here -- the
/// actual Arabic/translation text always comes from the active
/// QuranService (live backend, or the bundled sample data offline), never
/// hardcoded in this catalog.
class FeaturedVerseCatalog {
  FeaturedVerseCatalog._();

  static final _rng = math.Random();

  /// At least the ten most widely-recognized verses in the Quran, plus a
  /// few more well-loved ones for variety.
  static const List<(int, int)> candidates = [
    (1, 6),
    (2, 153),
    (2, 255), // Ayat al-Kursi
    (2, 286),
    (3, 159),
    (3, 200),
    (13, 28),
    (16, 97),
    (17, 23),
    (25, 63),
    (39, 53),
    (49, 13),
    (55, 13),
    (65, 3),
    (94, 5),
    (94, 6),
    (103, 1),
    (103, 2),
    (103, 3),
    (108, 1),
    (108, 2),
    (108, 3),
    (112, 1),
    (112, 2),
    (112, 3),
    (112, 4),
  ];

  static String _key(int s, int a) => '$s:$a';

  /// Ordered candidates for this app open: a verse different from whichever
  /// was shown last time is moved to the front, so Home shows a fresh
  /// verse on every launch instead of possibly repeating the last one; the
  /// rest follow in random order as offline-data fallbacks.
  static List<(int, int)> shuffledOrder() {
    String? last;
    try {
      last = Hive.box('app_flags_box').get('lastFeaturedVerse') as String?;
    } catch (_) {}
    final pool = [...candidates]..shuffle(_rng);
    if (last != null && pool.length > 1) {
      final idx = pool.indexWhere((c) => _key(c.$1, c.$2) == last);
      if (idx == 0) {
        // Move the last-shown verse to the end instead of the front.
        pool.add(pool.removeAt(0));
      }
    }
    return pool;
  }

  /// Records which verse Home actually ended up showing, so the next app
  /// open avoids repeating it immediately.
  static void markShown(int surahNumber, int ayahNumber) {
    try {
      Hive.box('app_flags_box')
          .put('lastFeaturedVerse', _key(surahNumber, ayahNumber));
    } catch (_) {}
  }
}
