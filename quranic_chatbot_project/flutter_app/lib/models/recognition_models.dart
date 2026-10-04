part of '../main.dart';

// ---------------------------------------------------------------------------
// Result and exception types for Recite & Recognize.
// ---------------------------------------------------------------------------

class RecognitionResult {
  const RecognitionResult({
    required this.ayah,
    required this.transcript,
    this.confidence,
  });

  final Ayah ayah;
  final String transcript;

  /// 0..1. Null unless the recognition service provides one.
  /// The UI must never invent a value.
  final double? confidence;
}

class RecognitionException implements Exception {
  const RecognitionException(this.type);
  final RecognitionErrorType type;
}
