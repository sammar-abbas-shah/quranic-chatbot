part of '../main.dart';

// ---------------------------------------------------------------------------
// Mock implementations used for UI experiments and tests.
// ---------------------------------------------------------------------------

// ============================================================================
// 5. MOCK SERVICES
// ============================================================================

String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

// ---------------------------------------------------------------- Quran

class MockQuranService implements QuranService {
  @override
  Future<List<Surah>> getSurahs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return SurahCatalog.all;
  }

  @override
  Future<List<Ayah>> getAyahs(int surahNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockQuranData.bySurah[surahNumber] ?? const [];
  }

  @override
  Future<List<Ayah>> getJuz(int juzNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final list = MockQuranData.all
        .where((a) => JuzCatalog.contains(juzNumber, a.surahNumber, a.ayahNumber))
        .toList()
      ..sort((a, b) => a.surahNumber != b.surahNumber
          ? a.surahNumber.compareTo(b.surahNumber)
          : a.ayahNumber.compareTo(b.ayahNumber));
    return list;
  }

  @override
  Future<Ayah?> getFeaturedAyah() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Try a few random candidates against the bundled sample set (which
    // only covers a handful of surahs), then fall back to any sample ayah
    // so the featured card is never empty while offline.
    for (final (s, a) in FeaturedVerseCatalog.shuffledOrder().take(6)) {
      final ayah = MockQuranData.find(s, a);
      if (ayah != null) {
        FeaturedVerseCatalog.markShown(s, a);
        return ayah;
      }
    }
    final all = MockQuranData.all;
    if (all.isEmpty) return null;
    final picked = all[math.Random().nextInt(all.length)];
    FeaturedVerseCatalog.markShown(picked.surahNumber, picked.ayahNumber);
    return picked;
  }

  @override
  Future<List<Ayah>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 450));
    final q = query.trim();
    if (q.isEmpty) return [];
    final all = MockQuranData.all;

    final ref = RegExp(r'^(\d{1,3})\s*[:\s]\s*(\d{1,3})$').firstMatch(q);
    if (ref != null) {
      final s = int.parse(ref.group(1)!);
      final a = int.parse(ref.group(2)!);
      return all.where((x) => x.surahNumber == s && x.ayahNumber == a).toList();
    }

    final lower = q.toLowerCase();
    final normQ = normalizeArabic(q);
    return all.where((x) {
      final surah = SurahCatalog.byNumber(x.surahNumber);
      return surah.englishName.toLowerCase().contains(lower) ||
          (normQ.isNotEmpty &&
              (normalizeArabic(surah.arabicName).contains(normQ) ||
                  normalizeArabic(x.arabicText).contains(normQ))) ||
          x.englishTranslation.toLowerCase().contains(lower) ||
          x.urduTranslation.contains(q);
    }).toList();
  }
}

// ----------------------------------------------------------------- Chat

class MockChatService implements ChatService {
  @override
  Future<ChatMessage> sendMessage({
    required String text,
    required String languageCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1400));
    return buildReply(text, languageCode);
  }

  static ChatMessage buildReply(String text, String lang) {
    final t = text.toLowerCase();
    List<Ayah> citations = const [];
    String body;

    if (t.contains('patience') || t.contains('sabr') || text.contains('صبر')) {
      body = _pick(lang, {
        'en':
            'The Quran presents patience (sabr) as a source of strength and a quality of the believers.\n\nThese verses speak about it directly:',
        'ur':
            'قرآن مجید صبر کو ایمان والوں کی ایک بڑی خوبی اور قوت کا ذریعہ قرار دیتا ہے۔\n\nیہ آیات اس بارے میں ہیں:',
        'ar':
            'يبيّن القرآن الكريم أن الصبر مصدر قوة وصفة من صفات المؤمنين.\n\nومن الآيات في ذلك:',
      });
      citations = [MockQuranData.find(2, 153)!, MockQuranData.find(3, 200)!];
    } else if (t.contains('asr') || text.contains('عصر')) {
      body = _pick(lang, {
        'en':
            'Surah Al-Asr is a short Surah of three verses.\n\nIt teaches that mankind is in loss, except those who believe, do righteous deeds, and encourage one another to truth and to patience.',
        'ur':
            'سورۃ العصر تین آیات پر مشتمل ایک مختصر سورت ہے۔\n\nاس میں بتایا گیا ہے کہ انسان خسارے میں ہے، سوائے ان کے جو ایمان لائیں، نیک عمل کریں اور حق اور صبر کی تلقین کریں۔',
        'ar':
            'سورة العصر سورة قصيرة من ثلاث آيات.\n\nتبيّن أن الإنسان في خسر إلا الذين آمنوا وعملوا الصالحات وتواصوا بالحق وتواصوا بالصبر.',
      });
      citations = MockQuranData.bySurah[103]!;
    } else {
      body = _pick(lang, {
        'en':
            'This is a placeholder reply from the mock assistant.\n\nOnce the backend is connected, answers grounded in Quranic verses will appear here with tappable citations.',
        'ur':
            'یہ فرضی معاون کا نمونہ جواب ہے۔\n\nبیک اینڈ جڑنے کے بعد یہاں قرآنی آیات پر مبنی جوابات حوالوں کے ساتھ دکھائے جائیں گے۔',
        'ar':
            'هذا رد تجريبي من المساعد الافتراضي.\n\nبعد ربط الخادم ستظهر هنا إجابات مبنية على الآيات القرآنية مع مراجع قابلة للنقر.',
      });
    }

    return ChatMessage(
      id: _newId(),
      text: body,
      isUser: false,
      time: DateTime.now(),
      language: lang,
      citations: citations,
    );
  }

  static String _pick(String lang, Map<String, String> m) =>
      m[lang] ?? m['en']!;
}

// ------------------------------------------------------ Speech-to-text

class MockSpeechRecognitionService implements SpeechRecognitionService {
  static const _sample = 'What does the Quran say about patience?';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startListening() async {}

  @override
  Future<String> stopListening() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return _sample;
  }

  @override
  Future<void> cancel() async {}
}

// ------------------------------------------------------ Text-to-speech

class MockTextToSpeechService implements TextToSpeechService {
  final ValueNotifier<TtsState> _state = ValueNotifier(const TtsState());
  Timer? _timer;
  int _remainingMs = 0;
  DateTime? _startedAt;

  @override
  ValueListenable<TtsState> get state => _state;

  @override
  Future<void> speak({
    required String id,
    required String text,
    required String languageCode,
  }) async {
    _timer?.cancel();
    _remainingMs = (text.length * 45).clamp(2500, 9000);
    _state.value = TtsState(id: id, status: TtsStatus.speaking);
    _run(id);
  }

  void _run(String id) {
    _startedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: _remainingMs), () {
      _state.value = const TtsState();
    });
  }

  @override
  Future<void> pause() async {
    final s = _state.value;
    if (s.status != TtsStatus.speaking) return;
    _timer?.cancel();
    _remainingMs -= DateTime.now().difference(_startedAt!).inMilliseconds;
    if (_remainingMs < 0) _remainingMs = 0;
    _state.value = TtsState(id: s.id, status: TtsStatus.paused);
  }

  @override
  Future<void> resume() async {
    final s = _state.value;
    if (s.status != TtsStatus.paused) return;
    _state.value = TtsState(id: s.id, status: TtsStatus.speaking);
    _run(s.id ?? '');
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _state.value = const TtsState();
  }
}

// ---------------------------------------------------- Verse recognition

class MockVerseRecognitionService implements VerseRecognitionService {
  DateTime? _startedAt;

  @override
  Future<void> startRecording() async {
    _startedAt = DateTime.now();
  }

  @override
  Future<RecognitionResult> stopAndRecognize() async {
    final elapsed = DateTime.now().difference(_startedAt ?? DateTime.now());
    await Future.delayed(const Duration(milliseconds: 2200));
    if (elapsed < const Duration(seconds: 2)) {
      throw const RecognitionException(
        RecognitionErrorType.insufficientRecording,
      );
    }
    final ayah = MockQuranData.find(2, 153)!;
    return RecognitionResult(
      ayah: ayah,
      transcript: 'يا أيها الذين آمنوا استعينوا بالصبر والصلاة',
      confidence: null, // the mock provides none, so the UI shows none
    );
  }

  @override
  Future<void> cancel() async {
    _startedAt = null;
  }
}

// ---------------------------------------------------------------- Audio

class MockAudioService implements AudioService {
  final ValueNotifier<PlaybackState> _state = ValueNotifier(
    const PlaybackState(),
  );
  final StreamController<String> _completeCtrl =
      StreamController<String>.broadcast();
  Timer? _timer;
  double _speed = 1.0;
  static const _duration = Duration(seconds: 12);

  @override
  ValueListenable<PlaybackState> get state => _state;

  @override
  Stream<String> get onTrackComplete => _completeCtrl.stream;

  @override
  Future<void> play(AudioTrack track) async {
    _timer?.cancel();
    _state.value = PlaybackState(
      trackId: track.id,
      status: PlaybackStatus.loading,
    );
    await Future.delayed(const Duration(milliseconds: 600));
    if (_state.value.trackId != track.id) return; // superseded
    _state.value = PlaybackState(
      trackId: track.id,
      status: PlaybackStatus.playing,
      position: Duration.zero,
      duration: _duration,
    );
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      final s = _state.value;
      if (s.status != PlaybackStatus.playing) return;
      final next = s.position + Duration(milliseconds: (200 * _speed).round());
      if (next >= s.duration) {
        t.cancel();
        _state.value = s.copyWith(
          status: PlaybackStatus.paused,
          position: Duration.zero,
        );
        if (s.trackId != null) _completeCtrl.add(s.trackId!);
      } else {
        _state.value = s.copyWith(position: next);
      }
    });
  }

  @override
  Future<void> pause() async {
    final s = _state.value;
    if (s.status == PlaybackStatus.playing) {
      _state.value = s.copyWith(status: PlaybackStatus.paused);
    }
  }

  @override
  Future<void> resume() async {
    final s = _state.value;
    if (s.status == PlaybackStatus.paused) {
      _state.value = s.copyWith(status: PlaybackStatus.playing);
      _startTicker();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    final s = _state.value;
    if (s.trackId == null) return;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > s.duration ? s.duration : position);
    _state.value = s.copyWith(position: clamped);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _state.value = const PlaybackState();
  }
}

// -------------------------------------------------------------- History

class MockHistoryService implements HistoryService {
  MockHistoryService() {
    final now = DateTime.now();
    _items = [
      _seed(
        'Patience in the Quran',
        'What does the Quran say about patience?',
        now.subtract(const Duration(minutes: 20)),
      ),
      _seed(
        'Meaning of Surah Al-Asr',
        'Explain Surah Al-Asr.',
        now.subtract(const Duration(days: 1, hours: 2)),
      ),
      _seed(
        'Verses about forgiveness',
        'What does the Quran say about forgiveness?',
        now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  late List<ChatConversation> _items;

  ChatConversation _seed(String title, String question, DateTime at) {
    final c = ChatConversation(
      id: _newId() + title.length.toString(),
      title: title,
      updatedAt: at,
    );
    c.messages.add(
      ChatMessage(id: '${c.id}u', text: question, isUser: true, time: at),
    );
    final reply = MockChatService.buildReply(question, 'en');
    c.messages.add(
      ChatMessage(
        id: '${c.id}a',
        text: reply.text,
        isUser: false,
        time: at,
        citations: reply.citations,
      ),
    );
    return c;
  }

  @override
  Future<List<ChatConversation>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final list = [..._items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> save(ChatConversation c) async {
    final i = _items.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      _items[i] = c;
    } else {
      _items.add(c);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> clear() async => _items.clear();
}
