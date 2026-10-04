part of '../main.dart';

// ---------------------------------------------------------------------------
// Audio player bar and the offline-audio settings tile.
// ---------------------------------------------------------------------------

/// Settings row: how much recitation audio is saved, with a delete button.
class OfflineAudioTile extends StatefulWidget {
  const OfflineAudioTile({super.key});

  @override
  State<OfflineAudioTile> createState() => _OfflineAudioTileState();
}

class _OfflineAudioTileState extends State<OfflineAudioTile> {
  final RecitationCache _cache = RecitationCache.instance;
  late Future<RecitationCacheStats> _stats = _load();

  Future<RecitationCacheStats> _load() => _cache
      .stats()
      .catchError((_) => const RecitationCacheStats(0, 0));

  @override
  void initState() {
    super.initState();
    _cache.revision.addListener(_refresh);
  }

  @override
  void dispose() {
    _cache.revision.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _stats = _load(); // (a Future must not be returned from setState)
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecitationCacheStats>(
      future: _stats,
      builder: (context, snap) {
        final files = snap.data?.files ?? 0;
        final bytes = snap.data?.bytes ?? 0;
        final has = files > 0;
        final hint = context.tr('offlineAudioHint');
        return ListTile(
          leading: const Icon(Icons.download_done_rounded),
          title: Text(context.tr('offlineAudio')),
          isThreeLine: has,
          subtitle: Text(
            has
                ? '$files ${context.tr('offlineVerses')} · '
                    '${formatFileSize(bytes)}\n$hint'
                : hint,
          ),
          trailing: IconButton(
            tooltip: context.tr('clearOfflineAudio'),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: !has
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final doneMsg = context.tr('offlineAudioCleared');
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(ctx.tr('confirm')),
                        content: Text(ctx.tr('clearOfflineAudioConfirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(ctx.tr('cancel')),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(ctx.tr('confirm')),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await _cache.clear();
                      messenger.showSnackBar(
                        SnackBar(content: Text(doneMsg)),
                      );
                    }
                  },
          ),
        );
      },
    );
  }
}

/// Reusable recitation player: play / pause / seek / replay / progress / duration.
class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({
    super.key,
    required this.track,
    this.compact = false,
  });
  final AudioTrack track;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final audio = context.appRead.audio;
    final settings = context.appRead.settings;

    // Media controls stay LTR in every language.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<PlaybackState>(
        valueListenable: audio.state,
        builder: (context, s, _) {
          final active = s.trackId == track.id;
          final status = active ? s.status : PlaybackStatus.idle;
          final pos = active ? s.position : Duration.zero;
          final dur = active ? s.duration : Duration.zero;
          final maxMs = dur.inMilliseconds.toDouble();
          final value =
              maxMs <= 0 ? 0.0 : (pos.inMilliseconds / maxMs).clamp(0.0, 1.0);
          final playing = status == PlaybackStatus.playing;

          Future<void> toggle() async {
            HapticFeedback.selectionClick();
            if (playing) {
              await audio.pause();
            } else if (active && status == PlaybackStatus.paused) {
              await audio.resume();
            } else {
              await audio.setSpeed(settings.playbackSpeed);
              try {
                await audio.play(track);
              } catch (e) {
                debugPrint('[audio] play failed for ${track.url}: $e');
                if (context.mounted) {
                  final msg = context.tr('err_audio_msg');
                  ScaffoldMessenger.maybeOf(context)
                    ?..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        // Debug builds also show the real reason on screen.
                        content: Text(kDebugMode ? '$msg\n$e' : msg),
                        duration: Duration(seconds: kDebugMode ? 10 : 4),
                      ),
                    );
                }
              }
            }
          }

          final timeText =
              '${formatDuration(pos)} / ${dur == Duration.zero ? '--:--' : formatDuration(dur)}';

          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: active && status != PlaybackStatus.idle
                  ? context.cs.primary.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: context.tr(playing ? 'pause' : 'play'),
                  onPressed: status == PlaybackStatus.loading ? null : toggle,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween(begin: 0.85, end: 1.0).animate(anim),
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: status == PlaybackStatus.loading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(playing),
                          ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: value,
                    semanticFormatterCallback: (_) => timeText,
                    onChanged: (active && maxMs > 0)
                        ? (v) => audio.seek(
                              Duration(milliseconds: (v * maxMs).round()),
                            )
                        : null,
                  ),
                ),
                Text(
                  timeText,
                  style:
                      AppTypography.caption(color: context.mutedText).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!compact)
                  IconButton(
                    tooltip: context.tr('replay'),
                    icon: const Icon(Icons.replay_rounded),
                    onPressed: active
                        ? () async {
                            await audio.seek(Duration.zero);
                            await audio.resume();
                          }
                        : null,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
