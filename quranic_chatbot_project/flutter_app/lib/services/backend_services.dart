part of '../main.dart';

// ---------------------------------------------------------------------------
// Quran and chat services that call the backend and parse its JSON.
// ---------------------------------------------------------------------------

// ============================================================================
// 13. BACKEND CONNECTION (uses your lib/services.dart)
// ============================================================================

/// Reads the first non-empty value among several possible JSON key names, so
/// small differences in your backend's field names don't break the app.
dynamic _pickKey(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && '$v'.trim().isNotEmpty) return v;
  }
  return null;
}

int? _asInt(dynamic v) {
  if (v is Map) v = v['id'] ?? v['number'];
  return int.tryParse('${v ?? ''}');
}

/// Converts one backend ayah JSON object into the app's Ayah.
/// Accepted keys (first match wins):
///   surah : surah_id, surah_number, surah, chapter ...   (or [surahHint])
///   ayah  : ayah_number, ayah, verse_number, verse ...   (or [indexHint]+1)
///   arabic: arabic, arabic_text, text_ar, text ...
///   english: english, english_translation, translation_en, translation ...
///   urdu  : urdu, urdu_translation, translation_ur ...
/// Returns null when the surah/ayah numbers can't be found. With [allowEmpty]
/// (used for chat citations) the texts may be empty and are filled in later.
Ayah? _parseAyah(Map m,
    {int? surahHint, int? indexHint, bool allowEmpty = false}) {
  final s = _asInt(_pickKey(m, [
        'surah_id',
        'surah_number',
        'surahId',
        'surah',
        'chapter',
        'chapter_id',
        'sura'
      ])) ??
      surahHint;
  final a = _asInt(_pickKey(m, [
        'ayah_number',
        'ayahNumber',
        'ayah',
        'ayah_id',
        'verse_number',
        'verse',
        'verse_id',
        'number'
      ])) ??
      (indexHint != null ? indexHint + 1 : null);
  if (s == null || a == null || s < 1 || s > 114 || a < 1) return null;

  final arabic = '${_pickKey(m, [
            'arabic',
            'arabic_text',
            'text_arabic',
            'text_ar',
            'ar',
            'text_uthmani',
            'uthmani',
            'text'
          ]) ?? ''}';
  final english = '${_pickKey(m, [
            'english',
            'english_translation',
            'translation_en',
            'text_en',
            'en',
            'translation_english',
            'translation'
          ]) ?? ''}';
  final urdu = '${_pickKey(m, [
            'urdu',
            'urdu_translation',
            'translation_ur',
            'text_ur',
            'ur',
            'translation_urdu'
          ]) ?? ''}';
  if (!allowEmpty && arabic.isEmpty && english.isEmpty && urdu.isEmpty) {
    return null;
  }
  final audio = _pickKey(m, ['audio_url', 'audioUrl', 'audio']);
  return Ayah(
    surahNumber: s,
    ayahNumber: a,
    arabicText: arabic,
    englishTranslation: english,
    urduTranslation: urdu,
    audioUrl: audio != null ? '$audio' : MockQuranData._audio(s, a),
  );
}

/// Adapts your HttpQuranService to the app's QuranService interface, so the
/// whole Quran UI runs on your backend without any screen changes.
class BackendQuranService implements QuranService {
  BackendQuranService(this._api, this._fallback);
  final api.HttpQuranService _api;
  final QuranService _fallback; // sample data, used only as a safety net

  /// Surah names are safe to fall back to (the catalog is built in).
  @override
  Future<List<Surah>> getSurahs() async {
    try {
      final raw = await _api.getSurahs();
      final list =
          raw.whereType<Map>().map(_surahFromJson).whereType<Surah>().toList();
      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('Backend getSurahs failed, using built-in list: $e');
    }
    return _fallback.getSurahs();
  }

  /// Quran text is never faked: if the backend fails, the error is shown
  /// (with a Retry button) instead of substituting sample text.
  @override
  Future<List<Ayah>> getAyahs(int surahNumber) async {
    try {
      final raw = await _api.getAyahs(surahNumber);
      final out = <Ayah>[];
      for (var i = 0; i < raw.length; i++) {
        final item = raw[i];
        if (item is! Map) continue;
        final a = _parseAyah(item, surahHint: surahNumber, indexHint: i);
        if (a != null) out.add(a);
      }
      out.sort((x, y) => x.ayahNumber.compareTo(y.ayahNumber));
      return out;
    } catch (e) {
      debugPrint('Backend getAyahs($surahNumber) failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<Ayah>> getJuz(int juzNumber) async {
    try {
      final raw = await _api.getJuz(juzNumber);
      final out = <Ayah>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final a = _parseAyah(item);
        if (a != null) out.add(a);
      }
      out.sort((x, y) => x.surahNumber != y.surahNumber
          ? x.surahNumber.compareTo(y.surahNumber)
          : x.ayahNumber.compareTo(y.ayahNumber));
      return out;
    } catch (e) {
      debugPrint('Backend getJuz($juzNumber) failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<Ayah>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final raw = await _api.search(q);
      return raw
          .whereType<Map>()
          .map((m) => _parseAyah(m))
          .whereType<Ayah>()
          .toList();
    } catch (e) {
      debugPrint('Backend search failed: $e');
      rethrow;
    }
  }

  /// Featured verse rotates every time this is called (see
  /// FeaturedVerseCatalog) so Home doesn't show the same verse on every
  /// app open; falls back to the sample data if the backend is offline.
  @override
  Future<Ayah?> getFeaturedAyah() async {
    for (final (surahNo, ayahNo)
        in FeaturedVerseCatalog.shuffledOrder().take(5)) {
      try {
        final list = await getAyahs(surahNo);
        for (final a in list) {
          if (a.ayahNumber == ayahNo) {
            FeaturedVerseCatalog.markShown(surahNo, ayahNo);
            return a;
          }
        }
      } catch (_) {
        // Try the next candidate rather than giving up on the first miss.
      }
    }
    return _fallback.getFeaturedAyah();
  }

  /// Backend JSON: {id, name_english, name_arabic, ...}. Optional keys
  /// ayah_count / revelation_type are used if present, else the catalog.
  Surah? _surahFromJson(Map m) {
    final n = int.tryParse('${m['id'] ?? m['number']}');
    if (n == null || n < 1 || n > 114) return null;
    final cat = SurahCatalog.byNumber(n);
    final rt = '${m['revelation_type'] ?? m['type'] ?? ''}'.toLowerCase();
    return Surah(
      number: n,
      arabicName: '${m['name_arabic'] ?? cat.arabicName}',
      englishName: '${m['name_english'] ?? cat.englishName}',
      ayahCount: int.tryParse('${m['ayah_count'] ?? m['total_ayahs'] ?? ''}') ??
          cat.ayahCount,
      revelationType: rt.startsWith('med')
          ? RevelationType.medinan
          : rt.startsWith('mec')
              ? RevelationType.meccan
              : cat.revelationType,
    );
  }
}

/// Adapts your HttpChatService (POST /chat) to the app's ChatService.
/// Expected response: {"text": "...", "citations": [ ayah objects or "2:153" ]}
/// (answer/response/reply and verses/references/sources are also accepted).
/// Citations that only carry surah/ayah numbers are completed with the
/// verse text from the Quran service.
class BackendChatService implements ChatService {
  BackendChatService(this._api, this._quran);
  final api.HttpChatService _api;
  final QuranService _quran;

  @override
  Future<ChatMessage> sendMessage({
    required String text,
    required String languageCode,
  }) async {
    final Map<String, dynamic> res;
    try {
      res = await _api.sendChatMessage(text, language: languageCode);
    } catch (e) {
      debugPrint('Backend chat failed: $e');
      rethrow; // ChatController shows the error bar with Retry
    }

    final answer = '${_pickKey(res, [
              'text',
              'answer',
              'response',
              'reply',
              'message'
            ]) ?? ''}';
    final rawCitations =
        _pickKey(res, ['citations', 'verses', 'references', 'sources']);

    final citations = <Ayah>[];
    if (rawCitations is List) {
      for (final c in rawCitations) {
        final ayah = await _citationToAyah(c);
        if (ayah != null && !citations.any((x) => x.key == ayah.key)) {
          citations.add(ayah);
        }
      }
    }

    return ChatMessage(
      id: _newId(),
      text: answer.isEmpty ? '…' : answer,
      isUser: false,
      time: DateTime.now(),
      language: languageCode,
      citations: citations,
    );
  }

  Future<Ayah?> _citationToAyah(dynamic c) async {
    Ayah? ayah;
    if (c is Map) {
      ayah = _parseAyah(c, allowEmpty: true);
    } else if (c is String) {
      final m = RegExp(r'(\d{1,3})\s*[:\-]\s*(\d{1,3})').firstMatch(c);
      if (m != null) {
        ayah = _parseAyah({'surah': m.group(1), 'ayah': m.group(2)},
            allowEmpty: true);
      }
    }
    if (ayah == null) return null;
    if (ayah.arabicText.isNotEmpty) return ayah;
    // Only a reference was sent: fetch the verse text.
    try {
      for (final a in await _quran.getAyahs(ayah.surahNumber)) {
        if (a.ayahNumber == ayah.ayahNumber) return a;
      }
    } catch (_) {}
    return null;
  }
}
