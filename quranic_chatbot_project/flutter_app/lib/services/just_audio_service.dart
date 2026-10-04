part of '../main.dart';

// ---------------------------------------------------------------------------
// Real audio player (just_audio) including the Auto Play completion logic.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------- Recitation player
//
// Plays the per-verse MP3 (Ayah.audioUrl, served by the backend from
// everyayah.com) with the just_audio package and maps its streams onto the
// app's PlaybackState, so AudioPlayerWidget works unchanged. Every verse is
// saved by RecitationCache on first play and played from disk afterwards.

class JustAudioService implements AudioService {
  JustAudioService() {
    _player.playerStateStream.listen(_onPlayerState);
    _player.positionStream.listen(_onPosition);
    _player.durationStream.listen(_onDuration);
    // Errors that happen mid-playback (network drop, bad file): reset the UI
    // instead of leaving the button spinning.
    _player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace _) {
      debugPrint('Audio playback error: $e');
      _reset();
    });
  }

  final ja.AudioPlayer _player = ja.AudioPlayer();
  final ValueNotifier<PlaybackState> _state =
      ValueNotifier(const PlaybackState());
  final StreamController<String> _completeCtrl =
      StreamController<String>.broadcast();
  String? _trackId;
  double _speed = 1.0;

  // True from the moment play() starts swapping in a new source until that
  // source is loaded. Player events in that window still belong to the
  // PREVIOUS verse (its rewind, its echoed "completed") and must not touch
  // the state of the verse that is loading.
  bool _switching = false;
  // play() has been issued but the player hasn't reported playing=true yet.
  bool _starting = false;
  // A verse reports "finished" exactly once per play().
  bool _completionFired = false;

  @override
  ValueListenable<PlaybackState> get state => _state;

  @override
  Stream<String> get onTrackComplete => _completeCtrl.stream;

  void _reset() {
    _trackId = null;
    _switching = false;
    _starting = false;
    _state.value = const PlaybackState();
  }

  void _onPlayerState(ja.PlayerState ps) {
    debugPrint('[audio] state=${ps.processingState.name} '
        'playing=${ps.playing} track=$_trackId');
    if (_trackId == null || _switching) return;
    switch (ps.processingState) {
      case ja.ProcessingState.loading:
      case ja.ProcessingState.buffering:
        _state.value = _state.value.copyWith(status: PlaybackStatus.loading);
        break;
      case ja.ProcessingState.ready:
        if (ps.playing) {
          _starting = false;
          _state.value = _state.value.copyWith(status: PlaybackStatus.playing);
        } else if (_starting) {
          // play() was just issued; keep showing "loading" instead of
          // flickering to "paused" (which would drop the card highlight).
          _state.value = _state.value.copyWith(status: PlaybackStatus.loading);
        } else {
          _state.value = _state.value.copyWith(status: PlaybackStatus.paused);
        }
        break;
      case ja.ProcessingState.completed:
        // just_audio emits `completed` again when we pause() below. Only the
        // first one counts, otherwise Auto Play would fire twice and skip a
        // verse.
        if (_completionFired) return;
        _completionFired = true;
        _starting = false;
        final finished = _trackId!;
        // Finished: rewind and sit in "paused" so the play button replays it.
        _player.pause();
        _player.seek(Duration.zero);
        _state.value = _state.value.copyWith(
          status: PlaybackStatus.paused,
          position: Duration.zero,
        );
        _completeCtrl.add(finished);
        break;
      case ja.ProcessingState.idle:
        break;
    }
  }

  void _onPosition(Duration p) {
    if (_trackId == null) return;
    final s = _state.value;
    if (s.status == PlaybackStatus.idle) return;
    _state.value = s.copyWith(position: p);
  }

  void _onDuration(Duration? d) {
    if (_trackId == null || d == null) return;
    _state.value = _state.value.copyWith(duration: d);
  }

  /// Throws if the verse can't be loaded, so the UI can tell the user.
  @override
  Future<void> play(AudioTrack track) async {
    if (track.url.isEmpty) {
      throw StateError('No audio URL for ${track.id}');
    }
    debugPrint('[audio] play ${track.id} <- ${track.url}');
    _trackId = track.id;
    _switching = true;
    _starting = false;
    _completionFired = false;
    _state.value = PlaybackState(
      trackId: track.id,
      status: PlaybackStatus.loading,
    );
    try {
      // Local-first: play the saved copy if we have one. Otherwise download
      // it once (this is what makes the verse work offline next time).
      final cache = RecitationCache.instance;
      File? local = await cache.cachedFile(track.url);
      if (local == null) {
        try {
          local = await cache.fetch(track.url);
        } catch (e) {
          debugPrint('Recitation download failed, trying to stream: $e');
        }
      }
      if (_trackId != track.id) return; // another verse was tapped meanwhile
      debugPrint('[audio] source: '
          '${local != null ? 'saved file ${local.path}' : 'streaming'}');
      if (local != null) {
        try {
          await _player.setFilePath(local.path);
        } on ja.PlayerInterruptedException {
          rethrow;
        } catch (e) {
          // Corrupt or partial file: delete it and stream instead.
          debugPrint('Saved audio unusable, deleting it: $e');
          await cache.delete(track.url);
          await _player.setUrl(track.url);
        }
      } else {
        await _player.setUrl(track.url);
      }
      if (_trackId != track.id) return;
      await _player.setSpeed(_speed);
      if (_trackId != track.id) return;
      _starting = true;
      _switching = false;
      // play() only completes when playback ends/pauses, so don't await it.
      unawaited(_player.play());
    } on ja.PlayerInterruptedException {
      // Superseded by a newer play()/stop(): nothing to report.
    } catch (e) {
      debugPrint('Audio load failed for ${track.url}: $e');
      if (_trackId == track.id) _reset();
      rethrow;
    }
  }

  @override
  Future<void> pause() {
    _starting = false;
    return _player.pause();
  }

  @override
  Future<void> resume() async {
    unawaited(_player.play());
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    if (_trackId != null) await _player.setSpeed(speed);
  }

  @override
  Future<void> stop() async {
    _reset();
    await _player.stop();
  }

  Future<void> dispose() {
    _completeCtrl.close();
    return _player.dispose();
  }
}
