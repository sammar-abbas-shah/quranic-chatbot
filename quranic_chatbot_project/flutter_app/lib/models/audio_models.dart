part of '../main.dart';

// ---------------------------------------------------------------------------
// AudioTrack (what the player is asked to play).
// ---------------------------------------------------------------------------

class AudioTrack {
  const AudioTrack({required this.id, required this.url, required this.title});
  final String id;
  final String url;
  final String title;
}
