part of '../main.dart';

// ---------------------------------------------------------------------------
// Surah list state.
// ---------------------------------------------------------------------------

// ============================================================================
// 9. CONTROLLERS (ChangeNotifier state)
// ============================================================================

class QuranController extends ChangeNotifier {
  QuranController(this._service);
  final QuranService _service;

  LoadState surahState = LoadState.loading;
  List<Surah> surahs = [];
  final Map<int, List<Ayah>> _ayahCache = {};

  Future<void> loadSurahs() async {
    surahState = LoadState.loading;
    notifyListeners();
    try {
      surahs = await _service.getSurahs();
      surahState = surahs.isEmpty ? LoadState.empty : LoadState.loaded;
    } catch (_) {
      surahState = LoadState.error;
    }
    notifyListeners();
  }

  /// Cached per Surah (offline-friendly). Throws on failure so callers can
  /// show an error state.
  Future<List<Ayah>> getAyahs(int surahNumber) async {
    final cached = _ayahCache[surahNumber];
    if (cached != null) return cached;
    final list = await _service.getAyahs(surahNumber);
    if (list.isNotEmpty) _ayahCache[surahNumber] = list;
    return list;
  }

  /// Cached per Juz (offline-friendly), same pattern as getAyahs above.
  final Map<int, List<Ayah>> _juzCache = {};
  Future<List<Ayah>> getJuz(int juzNumber) async {
    final cached = _juzCache[juzNumber];
    if (cached != null) return cached;
    final list = await _service.getJuz(juzNumber);
    if (list.isNotEmpty) _juzCache[juzNumber] = list;
    return list;
  }

  Future<Ayah?> findAyah(int surahNumber, int ayahNumber) async {
    try {
      final list = await getAyahs(surahNumber);
      for (final a in list) {
        if (a.ayahNumber == ayahNumber) return a;
      }
    } catch (_) {}
    return null;
  }
}
