part of '../main.dart';

// ---------------------------------------------------------------------------
// Verse search.
// ---------------------------------------------------------------------------

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  LoadState _state = LoadState.loaded;
  List<Ayah> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    final q = v.trim();
    setState(() {
      _query = q;
      _state = q.isEmpty ? LoadState.loaded : LoadState.loading;
      if (q.isEmpty) _results = const [];
    });
    if (q.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(q));
  }

  Future<void> _run(String q) async {
    final service = context.appRead.quranService;
    try {
      final r = await service.search(q);
      if (!mounted || q != _query) return;
      setState(() {
        _results = r;
        _state = r.isEmpty ? LoadState.empty : LoadState.loaded;
      });
    } catch (_) {
      if (!mounted || q != _query) return;
      setState(() => _state = LoadState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.tr('searchQuran'),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _query.isEmpty
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : IconButton(
                      key: const ValueKey('clear'),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
        ),
      ),
      body: ContentWidth(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey('${_query.isEmpty}-${_state.name}'),
            child: _body(context),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_query.isEmpty) {
      return EmptyState(
        icon: Icons.manage_search_rounded,
        title: context.tr('searchQuran'),
        message: context.tr('searchHint'),
      );
    }
    switch (_state) {
      case LoadState.loading:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                context.tr('searching'),
                style: AppTypography.caption(color: context.mutedText),
              ),
            ),
            const Expanded(child: SkeletonList(count: 3, itemHeight: 150)),
          ],
        );
      case LoadState.error:
        return AppErrorWidget(
          type: AppErrorType.network,
          onRetry: () => _run(_query),
        );
      case LoadState.empty:
        return EmptyState(
          icon: Icons.search_off_rounded,
          title: context.tr('noResults'),
          message: context.tr('noResultsMsg'),
        );
      case LoadState.loaded:
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _results.length,
          itemBuilder: (_, i) => FadeSlideIn(
            enabled: i < 6,
            delay: Duration(milliseconds: 50 * (i < 6 ? i : 0)),
            child: _ResultCard(ayah: _results[i], query: _query),
          ),
        );
    }
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.ayah, required this.query});
  final Ayah ayah;
  final String query;

  @override
  Widget build(BuildContext context) {
    final surah = SurahCatalog.byNumber(ayah.surahNumber);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.surah,
        arguments: SurahArgs(ayah.surahNumber, ayah.ayahNumber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.tr('surah')} ${surah.englishName} — ${ayah.key}',
            style: AppTypography.body(color: context.cs.primary)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Text(
              ayah.arabicText,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicQuran(
                size: 24,
                color: context.cs.onSurface,
              ).copyWith(height: 1.8),
            ),
          ),
          const SizedBox(height: 6),
          TranslationCard(
            languageCode: 'en',
            text: ayah.englishTranslation,
            query: query,
          ),
          const SizedBox(height: 6),
          TranslationCard(
            languageCode: 'ur',
            text: ayah.urduTranslation,
            query: query,
          ),
          const SizedBox(height: 6),
          AudioPlayerWidget(
            track: AudioTrack(
              id: ayah.key,
              url: ayah.audioUrl ?? '',
              title: ayah.key,
            ),
            compact: true,
          ),
        ],
      ),
    );
  }
}
