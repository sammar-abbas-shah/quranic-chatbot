part of '../main.dart';

// ---------------------------------------------------------------------------
// Surah and Juz lists.
// ---------------------------------------------------------------------------

class QuranListScreen extends StatefulWidget {
  const QuranListScreen({super.key});

  @override
  State<QuranListScreen> createState() => _QuranListScreenState();
}

class _QuranListScreenState extends State<QuranListScreen> {
  String _query = '';
  RevelationType? _filter;
  bool _juzMode = false;

  List<Surah> _apply(List<Surah> all) {
    final q = _query.trim().toLowerCase();
    return all.where((s) {
      if (_filter != null && s.revelationType != _filter) return false;
      if (q.isEmpty) return true;
      return s.englishName.toLowerCase().contains(q) ||
          s.arabicName.contains(q) ||
          s.number.toString() == q;
    }).toList();
  }

  List<int> _applyJuz() {
    final q = _query.trim();
    if (q.isEmpty) return List.generate(JuzCatalog.count, (i) => i + 1);
    final n = int.tryParse(q);
    return List.generate(JuzCatalog.count, (i) => i + 1)
        .where((j) => n != null ? j == n : JuzCatalog.rangeLabel(j)
            .toLowerCase()
            .contains(q.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final quran = context.app.quran;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('navQuran')),
        actions: [
          IconButton(
            tooltip: context.tr('searchQuran'),
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
        ],
      ),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text(context.tr('browseBySurah')),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.auto_stories_outlined, size: 18),
                      label: Text(context.tr('browseByJuz')),
                    ),
                  ],
                  selected: {_juzMode},
                  onSelectionChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _juzMode = v.first;
                      _query = '';
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: _juzMode
                      ? context.tr('searchJuz')
                      : context.tr('searchSurahs'),
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            if (!_juzMode)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final (label, value) in <(String, RevelationType?)>[
                      ('all', null),
                      ('meccan', RevelationType.meccan),
                      ('medinan', RevelationType.medinan),
                    ])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(context.tr(label)),
                          selected: _filter == value,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _filter = value);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _juzMode ? _juzBody(context) : _body(context, quran),
            ),
          ],
        ),
      ),
    );
  }

  Widget _juzBody(BuildContext context) {
    final list = _applyJuz();
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: context.tr('noResults'),
        message: context.tr('noResultsMsg'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => FadeSlideIn(
        key: ValueKey('juz-${list[i]}'),
        enabled: i < 10,
        delay: Duration(milliseconds: 40 * (i < 10 ? i : 0)),
        child: _JuzTile(juzNumber: list[i]),
      ),
    );
  }

  Widget _body(BuildContext context, QuranController quran) {
    switch (quran.surahState) {
      case LoadState.loading:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                context.tr('loadingQuran'),
                style: AppTypography.caption(color: context.mutedText),
              ),
            ),
            const Expanded(child: SkeletonList()),
          ],
        );
      case LoadState.error:
        return AppErrorWidget(
          type: AppErrorType.network,
          onRetry: quran.loadSurahs,
        );
      case LoadState.empty:
      case LoadState.loaded:
        final list = _apply(quran.surahs);
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: context.tr('noResults'),
            message: context.tr('noResultsMsg'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => FadeSlideIn(
            key: ValueKey('surah-${list[i].number}'),
            enabled: i < 10,
            delay: Duration(milliseconds: 40 * (i < 10 ? i : 0)),
            child: _SurahTile(surah: list[i]),
          ),
        );
    }
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah});
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final type = context.tr(
      surah.revelationType == RevelationType.meccan ? 'meccan' : 'medinan',
    );
    return Semantics(
      button: true,
      label:
          '${surah.number}, ${surah.englishName}, ${surah.ayahCount} ${context.tr('ayahs')}',
      child: AppCard(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.surah,
          arguments: SurahArgs(surah.number),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            NumberBadge(surah.number),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.englishName,
                    style: AppTypography.body(
                      size: 16,
                      color: context.cs.onSurface,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${surah.ayahCount} ${context.tr('ayahs')} · $type',
                    style: AppTypography.caption(color: context.mutedText),
                  ),
                ],
              ),
            ),
            Text(
              surah.arabicName,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicQuran(
                size: 24,
                color: context.cs.primary,
              ).copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _JuzTile extends StatelessWidget {
  const _JuzTile({required this.juzNumber});
  final int juzNumber;

  @override
  Widget build(BuildContext context) {
    final label = JuzCatalog.rangeLabel(juzNumber);
    return Semantics(
      button: true,
      label: '${context.tr('juz')} $juzNumber, $label',
      child: AppCard(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.juz,
          arguments: JuzArgs(juzNumber),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            NumberBadge(juzNumber),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tr('juz')} $juzNumber',
                    style: AppTypography.body(
                      size: 16,
                      color: context.cs.onSurface,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    label,
                    style: AppTypography.caption(color: context.mutedText),
                  ),
                ],
              ),
            ),
            Icon(context.forwardIcon, size: 18, color: context.mutedText),
          ],
        ),
      ),
    );
  }
}

class ReadingOptionsSheet extends StatelessWidget {
  const ReadingOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.app.settings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('readingOptions'),
              style: AppTypography.heading(
                size: 20,
                color: context.cs.onSurface,
              ),
            ),
            SwitchListTile(
              title: Text(context.tr('showArabic')),
              value: s.showArabic,
              onChanged: s.setShowArabic,
            ),
            SwitchListTile(
              title: Text(context.tr('showTranslation')),
              value: s.showTranslation,
              onChanged: s.setShowTranslation,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'en',
                      label: Text(context.tr('english')),
                    ),
                    ButtonSegment(value: 'ur', label: Text(context.tr('urdu'))),
                    ButtonSegment(
                      value: 'both',
                      label: Text(context.tr('translationBoth')),
                    ),
                  ],
                  selected: {s.translationLanguage},
                  onSelectionChanged: (v) => s.setTranslationLanguage(v.first),
                ),
              ),
            ),
            ListTile(
              title: Text(context.tr('arabicFontSize')),
              subtitle: Slider(
                min: 20,
                max: 44,
                divisions: 12,
                label: s.arabicFontSize.round().toString(),
                value: s.arabicFontSize,
                onChanged: s.setArabicFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
