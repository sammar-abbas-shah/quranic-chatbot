part of '../main.dart';

// ---------------------------------------------------------------------------
// Small shared enums.
// ---------------------------------------------------------------------------

// ============================================================================
// 2. MODELS
// ============================================================================

enum RevelationType { meccan, medinan }

enum VoiceState { idle, listening, processing, speaking, error }

enum RecognitionErrorType {
  noSpeech,
  poorAudio,
  insufficientRecording,
  noMatch,
  network,
  serviceUnavailable,
  microphonePermission,
  unknown,
}
