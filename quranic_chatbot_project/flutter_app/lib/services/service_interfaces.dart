part of '../main.dart';

// ---------------------------------------------------------------------------
// Abstract service contracts (Quran, Chat, Speech, TTS, Recognition, Audio, Bookmarks, History) plus playback state.
// ---------------------------------------------------------------------------

// ============================================================================
// 4. SERVICE INTERFACES
// ============================================================================

abstract class QuranService {
  Future<List<Surah>> getSurahs();
  Future<List<Ayah>> getAyahs(int surahNumber);

  /// Every ayah in the given Juz/Para (1-30), in Quran order, spanning
  /// whichever Surahs that Juz covers (see JuzCatalog for boundaries).
  Future<List<Ayah>> getJuz(int juzNumber);
  Future<List<Ayah>> search(String query);
  Future<Ayah?> getFeaturedAyah();
}

abstract class ChatService {
  /// Future backend: LLM + RAG. Must return citations as [Ayah]s.
  Future<ChatMessage> sendMessage({
    required String text,
    required String languageCode,
  });
}

abstract class SpeechRecognitionService {
  Future<bool> isAvailable();

  /// Starts recording the microphone. Real speech-to-text APIs are
  /// request/response, not live-streaming, so there is no partial transcript
  /// while listening -- only after [stopListening] finishes.
  Future<void> startListening();

  /// Stops recording, uploads the audio, and returns the final transcript.
  Future<String> stopListening();

  /// Stops recording (if any) and discards it without transcribing.
  Future<void> cancel();
}

enum TtsStatus { idle, speaking, paused }

class TtsState {
  const TtsState({this.id, this.status = TtsStatus.idle});
  final String? id;
  final TtsStatus status;
}

abstract class TextToSpeechService {
  ValueListenable<TtsState> get state;

  /// Starts speaking; observe [state] for progress/completion.
  Future<void> speak({
    required String id,
    required String text,
    required String languageCode,
  });
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
}

abstract class VerseRecognitionService {
  Future<void> startRecording();

  /// Stops recording and identifies the verse.
  /// Throws [RecognitionException] with a specific [RecognitionErrorType].
  Future<RecognitionResult> stopAndRecognize();
  Future<void> cancel();
}

enum PlaybackStatus { idle, loading, playing, paused }

class PlaybackState {
  const PlaybackState({
    this.trackId,
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final String? trackId;
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;

  PlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
  }) =>
      PlaybackState(
        trackId: trackId,
        status: status ?? this.status,
        position: position ?? this.position,
        duration: duration ?? this.duration,
      );
}

abstract class AudioService {
  ValueListenable<PlaybackState> get state;

  /// Fires with a track's id each time that track finishes playing on its
  /// own (never on a manual pause/stop) -- used to auto-advance to the next
  /// Ayah when Settings > Auto Play is on.
  Stream<String> get onTrackComplete;
  Future<void> play(AudioTrack track);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> stop();
}

abstract class BookmarkService {
  Future<List<Bookmark>> getAll();
  Future<void> add(Bookmark bookmark);
  Future<void> remove(int surahNumber, int ayahNumber);
  Future<void> clear();
}

abstract class HistoryService {
  Future<List<ChatConversation>> getAll();
  Future<void> save(ChatConversation conversation);
  Future<void> delete(String id);
  Future<void> clear();
}
