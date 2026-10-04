part of '../main.dart';

// ---------------------------------------------------------------------------
// Single-verse screen.
// ---------------------------------------------------------------------------

/// Single Ayah detail: full card + "Open Surah" + "Ask AI".
class AyahScreen extends StatefulWidget {
  const AyahScreen({super.key, required this.args});
  final SurahArgs args;

  @override
  State<AyahScreen> createState() => _AyahScreenState();
}

class _AyahScreenState extends State<AyahScreen> {
  late final Future<Ayah?> _future;
  bool _autoPlayed = false;

  @override
  void initState() {
    super.initState();
    _future = context.appRead.quran.findAyah(
      widget.args.surahNumber,
      widget.args.initialAyah ?? 1,
    );
  }

  void _maybeAutoPlay(Ayah a) {
    if (_autoPlayed) return;
    _autoPlayed = true;
    final settings = context.appRead.settings;
    if (!settings.autoPlay) return;
    final audio = context.appRead.audio;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await audio.setSpeed(settings.playbackSpeed);
      try {
        await audio.play(
          AudioTrack(id: a.key, url: a.audioUrl ?? '', title: a.key),
        );
      } catch (_) {
        // Auto-play is best effort; the play button still works.
      }
    });
  }

  @override
  void dispose() {
    context.appRead.audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surah = SurahCatalog.byNumber(widget.args.surahNumber);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${surah.englishName} ${widget.args.surahNumber}:${widget.args.initialAyah ?? 1}',
        ),
      ),
      body: FutureBuilder<Ayah?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return LoadingWidget(message: context.tr('loadingSurah'));
          }
          final a = snap.data;
          if (a == null) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: context.tr('noResults'),
              message: context.tr('surahNotBundled'),
              actionLabel: context.tr('goBack'),
              onAction: () => Navigator.pop(context),
            );
          }
          _maybeAutoPlay(a);
          return ContentWidth(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                FadeSlideIn(
                  child: QuranAyahCard(ayah: a, showSurahHeader: true),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.surah,
                            arguments: SurahArgs(a.surahNumber, a.ayahNumber),
                          ),
                          child: Text(
                            '${context.tr('surah')} ${surah.englishName}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: Text(context.tr('askAi')),
                          onPressed: () {
                            context.appRead.chat.startWithAyah(a);
                            AppNav.goToTab(context, 2);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
