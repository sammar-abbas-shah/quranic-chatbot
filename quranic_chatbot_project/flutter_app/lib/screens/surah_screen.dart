part of '../main.dart';

// ---------------------------------------------------------------------------
// Surah reader with Auto Play.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------- Surah reader

class SurahScreen extends StatefulWidget {
  const SurahScreen({super.key, required this.args});
  final SurahArgs args;

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  late Future<List<Ayah>> _future;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};
  bool _jumped = false;
  Timer? _progressDebounce;
  List<Ayah> _loaded = const [];
  StreamSubscription<String>? _completeSub;
  late final AudioService _audio;
  // Once a verse of this Surah has played, the "came from search" highlight
  // steps aside so only the verse being recited is lit.
  bool _playbackStarted = false;
  String? _prefetchedFor;

  @override
  void initState() {
    super.initState();
    _load();
    // "Continue reading" remembers the last opened Surah/Ayah, and then
    // keeps tracking the topmost visible ayah as the user scrolls, so
    // leaving mid-Surah and reopening the app resumes at the right verse.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.appRead.settings.setLastRead(
        widget.args.surahNumber,
        widget.args.initialAyah ?? 1,
      );
    });
    _scroll.addListener(_onScroll);
    // Auto Play (Settings): when the currently-playing Ayah finishes on its
    // own, move on to the next one until the end of the Surah.
    _audio = context.appRead.audio;
    _completeSub = _audio.onTrackComplete.listen(_onTrackComplete);
    _audio.state.addListener(_onAudioState);
  }

  /// Tracks which verse of this Surah is active: drops the search-target
  /// highlight once playback starts, and pre-downloads the following verse
  /// (when Auto Play is on) so the hand-off is instant.
  void _onAudioState() {
    if (!mounted) return;
    final s = _audio.state.value;
    final id = s.trackId;
    if (id == null) return;
    if (s.status != PlaybackStatus.playing &&
        s.status != PlaybackStatus.loading) {
      return;
    }
    if (_playbackStarted && id == _prefetchedFor) return;
    final idx = _loaded.indexWhere((a) => a.key == id);
    if (idx < 0) return;
    if (!_playbackStarted) setState(() => _playbackStarted = true);
    if (id == _prefetchedFor) return;
    if (!context.appRead.settings.autoPlay) return;
    _prefetchedFor = id;
    final nextIdx = _nextPlayableIndex(_loaded, idx);
    if (nextIdx != null) _prefetchRecitation(_loaded[nextIdx].audioUrl);
  }

  Future<void> _onTrackComplete(String trackId) async {
    if (!mounted) return;
    // A Surah screen hidden underneath another page must not also advance.
    if (!TickerMode.getNotifier(context).value) return;
    if (!context.appRead.settings.autoPlay) return;
    // The user may have tapped a different verse in the meantime.
    if (_audio.state.value.trackId != trackId) return;
    final idx = _loaded.indexWhere((a) => a.key == trackId);
    if (idx < 0) return;
    final nextIdx = _nextPlayableIndex(_loaded, idx);
    if (nextIdx == null) return; // end of Surah
    final next = _loaded[nextIdx];
    // Everything starts together: play() flips the state to "loading" for
    // the new verse straight away (its card lights up with no gap) and the
    // list scrolls to it while the audio loads.
    unawaited(_audio
        .setSpeed(context.appRead.settings.playbackSpeed)
        .catchError((Object _) {}));
    final started = _audio.play(
      AudioTrack(
        id: next.key,
        url: next.audioUrl ?? '',
        title: '${SurahCatalog.byNumber(next.surahNumber).englishName} '
            '${next.key}',
      ),
    );
    unawaited(_followListItem(
      controller: _scroll,
      keys: _keys,
      target: next.ayahNumber,
      stillWanted: () => mounted && _audio.state.value.trackId == next.key,
    ));
    try {
      await started;
    } catch (e) {
      debugPrint('[audio] auto-play failed for ${next.key}: $e');
      if (mounted) _showAudioErrorSnack(context, e);
    }
  }

  void _onScroll() {
    _progressDebounce?.cancel();
    _progressDebounce = Timer(const Duration(milliseconds: 500), _saveProgress);
  }

  /// Finds the ayah currently nearest the top of the viewport (only
  /// currently-built list items have a live position, so this only looks at
  /// those) and saves it as the reading position.
  void _saveProgress() {
    if (!mounted) return;
    const viewportTop = 90.0; // roughly below the app bar
    int? bestAyah;
    double bestDelta = double.infinity;
    for (final entry in _keys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      final delta = (dy - viewportTop).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        bestAyah = entry.key;
      }
    }
    if (bestAyah != null) {
      context.appRead.settings.setLastRead(widget.args.surahNumber, bestAyah);
    }
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    _saveProgress();
    _completeSub?.cancel();
    _audio.state.removeListener(_onAudioState);
    _audio.stop();
    _scroll.dispose();
    super.dispose();
  }

  void _load() {
    _future = context.appRead.quran.getAyahs(widget.args.surahNumber);
  }

  void _jumpToTarget(List<Ayah> ayahs) {
    if (_jumped) return;
    _jumped = true;
    final target = widget.args.initialAyah;
    if (target == null) return;
    final idx = ayahs.indexWhere((a) => a.ayahNumber == target);
    if (idx < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_keys[target]?.currentContext == null && _scroll.hasClients) {
        _scroll.jumpTo(
          math.min((idx + 1) * 330.0, _scroll.position.maxScrollExtent),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[target]?.currentContext;
        if (mounted && ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: 0.1,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final surah = SurahCatalog.byNumber(widget.args.surahNumber);
    return Scaffold(
      appBar: AppBar(
        title: Text(surah.englishName),
        actions: [
          IconButton(
            tooltip: context.tr('readingOptions'),
            icon: const Icon(Icons.text_fields_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const ReadingOptionsSheet(),
            ),
          ),
          IconButton(
            tooltip: context.tr('searchQuran'),
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
        ],
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    context.tr('loadingSurah'),
                    style: AppTypography.caption(color: context.mutedText),
                  ),
                ),
                const Expanded(child: SkeletonList(count: 4, itemHeight: 170)),
              ],
            );
          }
          if (snap.hasError) {
            return AppErrorWidget(
              type: AppErrorType.network,
              onRetry: () => setState(_load),
              onBack: () => Navigator.pop(context),
            );
          }
          final ayahs = snap.data ?? const <Ayah>[];
          _loaded = ayahs;
          if (ayahs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _SurahHeader(surah: surah),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    context.tr('surahNotBundled'),
                    textAlign: TextAlign.center,
                    style: AppTypography.body(color: context.mutedText),
                  ),
                ),
              ],
            );
          }
          _jumpToTarget(ayahs);
          final target = widget.args.initialAyah;
          final partial = ayahs.length < surah.ayahCount;
          return ContentWidth(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: ayahs.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return FadeSlideIn(
                    child: Column(
                      children: [
                        _SurahHeader(surah: surah),
                        if (partial)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              context.tr('previewNote'),
                              textAlign: TextAlign.center,
                              style: AppTypography.caption(
                                color: context.mutedText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                final a = ayahs[i - 1];
                return KeyedSubtree(
                  key: _keys.putIfAbsent(a.ayahNumber, () => GlobalKey()),
                  child: FadeSlideIn(
                    enabled: i <= 6,
                    delay: Duration(milliseconds: 60 * (i <= 6 ? i : 0)),
                    child: QuranAyahCard(
                      ayah: a,
                      highlight: !_playbackStarted && a.ayahNumber == target,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final type = context.tr(
      surah.revelationType == RevelationType.meccan ? 'meccan' : 'medinan',
    );
    // Bismillah banner (not for Al-Fatihah where it is Ayah 1, nor At-Tawbah).
    final showBismillah = surah.number != 1 && surah.number != 9;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.cs.primary.withOpacity(context.isDark ? 0.18 : 0.10),
            context.accentGold.withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.accentGold.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Text(
            surah.arabicName,
            style: AppTypography.arabicQuran(
              size: 36,
              color: context.cs.primary,
            ).copyWith(height: 1.6),
          ),
          Text(
            surah.englishName,
            style: AppTypography.heading(size: 18, color: context.cs.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.ayahCount} ${context.tr('ayahs')} · $type',
            style: AppTypography.caption(color: context.mutedText),
          ),
          if (showBismillah) ...[
            const SizedBox(height: 10),
            Divider(
                color: context.accentGold.withOpacity(0.4),
                indent: 40,
                endIndent: 40),
            const SizedBox(height: 6),
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: AppTypography.arabicQuran(
                size: 24,
                color: context.cs.onSurface,
              ).copyWith(height: 1.8),
            ),
          ],
        ],
      ),
    );
  }
}
