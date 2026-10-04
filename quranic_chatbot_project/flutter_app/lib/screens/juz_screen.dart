part of '../main.dart';

// ---------------------------------------------------------------------------
// Juz reader with Auto Play.
// ---------------------------------------------------------------------------

class JuzScreen extends StatefulWidget {
  const JuzScreen({super.key, required this.args});
  final JuzArgs args;

  @override
  State<JuzScreen> createState() => _JuzScreenState();
}

class _JuzScreenState extends State<JuzScreen> {
  late Future<List<Ayah>> _future;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {}; // keyed by position in the list
  List<Ayah> _loaded = const [];
  Timer? _progressDebounce;
  StreamSubscription<String>? _completeSub;
  late final AudioService _audio;
  String? _prefetchedFor;

  @override
  void initState() {
    super.initState();
    _load();
    context.appRead.settings.setLastJuz(widget.args.juzNumber);
    _scroll.addListener(_onScroll);
    // Auto Play (Settings): when the currently-playing Ayah finishes on its
    // own, move on to the next one until the end of the Juz.
    _audio = context.appRead.audio;
    _completeSub = _audio.onTrackComplete.listen(_onTrackComplete);
    _audio.state.addListener(_onAudioState);
  }

  void _load() {
    _future = context.appRead.quran.getJuz(widget.args.juzNumber);
  }

  /// Pre-downloads the verse after the active one (when Auto Play is on) so
  /// the hand-off is instant.
  void _onAudioState() {
    if (!mounted) return;
    final s = _audio.state.value;
    final id = s.trackId;
    if (id == null || id == _prefetchedFor) return;
    if (s.status != PlaybackStatus.playing &&
        s.status != PlaybackStatus.loading) {
      return;
    }
    if (!context.appRead.settings.autoPlay) return;
    final idx = _loaded.indexWhere((a) => a.key == id);
    if (idx < 0) return;
    _prefetchedFor = id;
    final nextIdx = _nextPlayableIndex(_loaded, idx);
    if (nextIdx != null) _prefetchRecitation(_loaded[nextIdx].audioUrl);
  }

  Future<void> _onTrackComplete(String trackId) async {
    if (!mounted) return;
    // A Juz screen hidden underneath another page must not also advance.
    if (!TickerMode.getNotifier(context).value) return;
    if (!context.appRead.settings.autoPlay) return;
    // The user may have tapped a different verse in the meantime.
    if (_audio.state.value.trackId != trackId) return;
    final idx = _loaded.indexWhere((a) => a.key == trackId);
    if (idx < 0) return;
    final nextIdx = _nextPlayableIndex(_loaded, idx);
    if (nextIdx == null) return; // end of Juz
    final next = _loaded[nextIdx];
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
      target: nextIdx,
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
    _progressDebounce =
        Timer(const Duration(milliseconds: 500), _saveProgress);
  }

  /// Same "topmost visible item" approach as SurahScreen, but resolved back
  /// to the (surah, ayah) actually on screen -- a Juz spans several Surahs,
  /// so the plain list position on its own isn't a useful reading position.
  void _saveProgress() {
    if (!mounted) return;
    const viewportTop = 90.0;
    int? bestIdx;
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
        bestIdx = entry.key;
      }
    }
    if (bestIdx != null && bestIdx < _loaded.length) {
      final a = _loaded[bestIdx];
      context.appRead.settings.setLastRead(a.surahNumber, a.ayahNumber);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${context.tr('juz')} ${widget.args.juzNumber}'),
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
                const SizedBox(height: 24),
                FadeSlideIn(child: _JuzBanner(juzNumber: widget.args.juzNumber)),
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
          return ContentWidth(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: ayahs.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return FadeSlideIn(
                    child: _JuzBanner(juzNumber: widget.args.juzNumber),
                  );
                }
                final idx = i - 1;
                final a = ayahs[idx];
                final newSurah =
                    idx == 0 || ayahs[idx - 1].surahNumber != a.surahNumber;
                return KeyedSubtree(
                  key: _keys.putIfAbsent(idx, () => GlobalKey()),
                  child: FadeSlideIn(
                    enabled: i <= 6,
                    delay: Duration(milliseconds: 60 * (i <= 6 ? i : 0)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (newSurah)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: SectionLabel(
                              '${SurahCatalog.byNumber(a.surahNumber).arabicName} '
                              '· ${SurahCatalog.byNumber(a.surahNumber).englishName}',
                            ),
                          ),
                        QuranAyahCard(ayah: a),
                      ],
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

class _JuzBanner extends StatelessWidget {
  const _JuzBanner({required this.juzNumber});
  final int juzNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            '${context.tr('juz')} $juzNumber',
            style:
                AppTypography.heading(size: 22, color: context.cs.primary),
          ),
          const SizedBox(height: 4),
          Text(
            JuzCatalog.rangeLabel(juzNumber),
            textAlign: TextAlign.center,
            style: AppTypography.caption(color: context.mutedText),
          ),
        ],
      ),
    );
  }
}
