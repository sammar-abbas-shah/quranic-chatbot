part of '../main.dart';

// ---------------------------------------------------------------------------
// Recite & Recognize state machine.
// ---------------------------------------------------------------------------

enum RecognitionStage { initial, recording, processing, result, failure }

class RecognitionController extends ChangeNotifier {
  RecognitionController(this._service);
  final VerseRecognitionService _service;

  static const maxRecording = Duration(seconds: 30);

  RecognitionStage stage = RecognitionStage.initial;
  Duration elapsed = Duration.zero;
  RecognitionResult? result;
  RecognitionErrorType? error;
  Timer? _timer;

  Future<void> start() async {
    try {
      await _service.startRecording();
    } catch (e) {
      if (e is RecognitionException) {
        failWith(e.type);
      } else {
        failWith(RecognitionErrorType.microphonePermission);
      }
      return;
    }
    elapsed = Duration.zero;
    result = null;
    error = null;
    stage = RecognitionStage.recording;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed += const Duration(seconds: 1);
      if (elapsed >= maxRecording) {
        stop();
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> stop() async {
    if (stage != RecognitionStage.recording) return;
    _timer?.cancel();
    stage = RecognitionStage.processing;
    notifyListeners();
    try {
      result = await _service.stopAndRecognize();
      stage = RecognitionStage.result;
    } on RecognitionException catch (e) {
      failWith(e.type);
      return;
    } catch (_) {
      failWith(RecognitionErrorType.unknown);
      return;
    }
    notifyListeners();
  }

  Future<void> cancelRecording() async {
    _timer?.cancel();
    await _service.cancel();
    reset();
  }

  void failWith(RecognitionErrorType type) {
    _timer?.cancel();
    error = type;
    stage = RecognitionStage.failure;
    notifyListeners();
  }

  void reset({bool notify = true}) {
    _timer?.cancel();
    stage = RecognitionStage.initial;
    elapsed = Duration.zero;
    result = null;
    error = null;
    if (notify) notifyListeners();
  }

  /// Silent teardown for State.dispose.
  void disposeSession() {
    _service.cancel();
    reset(notify: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
