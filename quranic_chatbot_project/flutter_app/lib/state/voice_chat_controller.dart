part of '../main.dart';

// ---------------------------------------------------------------------------
// Voice chat state machine.
// ---------------------------------------------------------------------------

class VoiceChatController extends ChangeNotifier {
  VoiceChatController(this._stt, this._tts, this._chat, this._settings) {
    _tts.state.addListener(_onTts);
  }
  final SpeechRecognitionService _stt;
  final TextToSpeechService _tts;
  final ChatController _chat;
  final SettingsController _settings;

  VoiceState state = VoiceState.idle;
  // Real speech-to-text is request/response, not live-streaming, so there is
  // no partial transcript while listening -- only an elapsed recording timer
  // until the user taps Send, then the final transcript appears.
  Duration elapsed = Duration.zero;
  String transcript = '';
  String? errorKey;
  ChatMessage? reply;
  Timer? _timer;

  void _onTts() {
    if (state == VoiceState.speaking &&
        _tts.state.value.status == TtsStatus.idle) {
      state = VoiceState.idle;
      notifyListeners();
    }
  }

  Future<void> start() async {
    await _tts.stop();
    if (!await _stt.isAvailable()) {
      _fail('err_microphone_msg');
      return;
    }
    transcript = '';
    reply = null;
    errorKey = null;
    elapsed = Duration.zero;
    try {
      await _stt.startListening();
    } catch (_) {
      _fail('err_microphone_msg');
      return;
    }
    state = VoiceState.listening;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  Future<void> send() async {
    if (state != VoiceState.listening) return;
    _timer?.cancel();
    state = VoiceState.processing;
    notifyListeners();

    String text;
    try {
      text = (await _stt.stopListening()).trim();
    } catch (_) {
      _fail('err_speechRecognition_msg');
      return;
    }
    if (text.isEmpty) {
      _fail('err_speechRecognition_msg');
      return;
    }
    transcript = text;
    notifyListeners();

    await _chat.send(text);
    if (_chat.hasError ||
        _chat.messages.isEmpty ||
        _chat.messages.last.isUser) {
      _fail('err_network_msg');
      return;
    }
    // The answer is shown as text only (no spoken playback).
    reply = _chat.messages.last;
    state = VoiceState.idle;
    notifyListeners();
  }

  Future<void> cancel() async {
    _timer?.cancel();
    await _stt.cancel();
    await _tts.stop();
    state = VoiceState.idle;
    transcript = '';
    reply = null;
    elapsed = Duration.zero;
    notifyListeners();
  }

  void failWith(String key) => _fail(key);

  void _fail(String key) {
    _timer?.cancel();
    errorKey = key;
    state = VoiceState.error;
    notifyListeners();
  }

  /// Silent teardown used from State.dispose (no notifications).
  void disposeSession() {
    _timer?.cancel();
    _stt.cancel();
    _tts.stop();
    state = VoiceState.idle;
    transcript = '';
    reply = null;
    errorKey = null;
    elapsed = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.state.removeListener(_onTts);
    super.dispose();
  }
}
