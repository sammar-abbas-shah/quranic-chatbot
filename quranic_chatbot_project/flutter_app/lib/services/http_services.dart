part of '../main.dart';

// ---------------------------------------------------------------------------
// Speech-to-text and verse-recognition services that call the backend.
// ---------------------------------------------------------------------------

// ---------------------------------------------------- Real audio services
//
// Real speech-to-text/recitation-recognition is request/response, not
// live-streaming: record -> stop -> upload -> get text back. Both classes
// below record to a temp file with the `record` package, then send it to
// your backend through HttpChatService (services.dart).

/// True if [error] looks like a network problem (no internet, DNS failure,
/// connection refused, timeout) rather than the server itself returning an
/// error status. Used so the app can show "You're offline" instead of
/// "Service unavailable" when that's what actually happened.
bool _looksLikeNetworkFailure(Object error) {
  if (error is SocketException || error is TimeoutException) return true;
  final m = error.toString().toLowerCase();
  return m.contains('socketexception') ||
      m.contains('failed host lookup') ||
      m.contains('connection refused') ||
      m.contains('connection closed') ||
      m.contains('network is unreachable') ||
      m.contains('timed out');
}

class HttpSpeechRecognitionService implements SpeechRecognitionService {
  HttpSpeechRecognitionService(this._api);
  final api.HttpChatService _api;
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  @override
  Future<bool> isAvailable() => _recorder.hasPermission();

  @override
  Future<void> startListening() async {
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _path!,
    );
  }

  @override
  Future<String> stopListening() async {
    final path = await _recorder.stop();
    final file = File(path ?? _path ?? '');
    if (!await file.exists()) return '';
    try {
      return await _api.speechToText(file);
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    final p = _path;
    if (p != null) {
      final f = File(p);
      if (await f.exists()) await f.delete();
    }
  }
}

class HttpVerseRecognitionService implements VerseRecognitionService {
  HttpVerseRecognitionService(this._api, this._quran);
  final api.HttpChatService _api;
  final QuranService _quran; // used to fetch full verse text if needed
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  @override
  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw const RecognitionException(
          RecognitionErrorType.microphonePermission);
    }
    final dir = await getTemporaryDirectory();
    _path =
        '${dir.path}/recitation_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _path!,
    );
  }

  @override
  Future<RecognitionResult> stopAndRecognize() async {
    final path = await _recorder.stop();
    final file = File(path ?? _path ?? '');
    if (!await file.exists()) {
      throw const RecognitionException(RecognitionErrorType.noSpeech);
    }

    Map<String, dynamic> data;
    try {
      data = await _api.recognizeRecitation(file);
    } catch (e) {
      // Check network failure FIRST: a dropped connection's message can
      // still happen to contain digits, so this must not fall through to
      // the status-code checks below.
      if (_looksLikeNetworkFailure(e)) {
        throw const RecognitionException(RecognitionErrorType.network);
      }
      final msg = e.toString();
      if (msg.contains('400') || msg.contains('no_speech')) {
        throw const RecognitionException(RecognitionErrorType.noSpeech);
      }
      if (msg.contains('404') || msg.contains('no_match')) {
        throw const RecognitionException(RecognitionErrorType.noMatch);
      }
      throw const RecognitionException(RecognitionErrorType.serviceUnavailable);
    } finally {
      if (await file.exists()) await file.delete();
    }

    final ayahJson = data['ayah'];
    if (ayahJson is! Map) {
      throw const RecognitionException(RecognitionErrorType.noMatch);
    }
    final surahNo =
        int.tryParse('${ayahJson['surah_id'] ?? ayahJson['surah'] ?? ''}');
    final ayahNo =
        int.tryParse('${ayahJson['ayah_number'] ?? ayahJson['ayah'] ?? ''}');
    if (surahNo == null || ayahNo == null) {
      throw const RecognitionException(RecognitionErrorType.noMatch);
    }

    // Prefer the verse text the backend already sends; fall back to looking
    // it up (works offline too, since QuranService reads through the cache).
    Ayah ayah = Ayah(
      surahNumber: surahNo,
      ayahNumber: ayahNo,
      arabicText: '${ayahJson['arabic'] ?? ''}',
      englishTranslation: '${ayahJson['english'] ?? ''}',
      urduTranslation: '${ayahJson['urdu'] ?? ''}',
      audioUrl: (ayahJson['audio_url'] is String &&
              (ayahJson['audio_url'] as String).isNotEmpty)
          ? ayahJson['audio_url'] as String
          : MockQuranData._audio(surahNo, ayahNo),
    );
    // Also look the verse up when the backend sent no translations, so the
    // English and Urdu text always show under the recognized Arabic.
    if (ayah.arabicText.isEmpty ||
        ayah.englishTranslation.isEmpty ||
        ayah.urduTranslation.isEmpty) {
      try {
        for (final a in await _quran.getAyahs(surahNo)) {
          if (a.ayahNumber == ayahNo) {
            ayah = a;
            break;
          }
        }
      } catch (_) {}
    }

    final confRaw = data['confidence'];
    return RecognitionResult(
      ayah: ayah,
      transcript: '${data['transcript'] ?? ''}',
      // Only set if the backend genuinely provides one -- the UI is built to
      // hide this row entirely when it's null, never showing a fake number.
      confidence: confRaw is num ? confRaw.toDouble() : null,
    );
  }

  @override
  Future<void> cancel() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    final p = _path;
    if (p != null) {
      final f = File(p);
      if (await f.exists()) await f.delete();
    }
  }
}
