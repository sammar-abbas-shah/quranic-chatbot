part of '../main.dart';

// ---------------------------------------------------------------------------
// Bookmarks screen.
// ---------------------------------------------------------------------------

enum _Sort { newest, oldest, surah }

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  String _query = '';
  _Sort _sort = _Sort.newest;

  List<Bookmark> _apply(List<Bookmark> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((b) {
      if (q.isEmpty) return true;
      final name =
          SurahCatalog.byNumber(b.surahNumber).englishName.toLowerCase();
      return name.contains(q) || b.key.contains(q);
    }).toList();
    switch (_sort) {
      case _Sort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _Sort.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _Sort.surah:
        list.sort(
          (a, b) => a.surahNumber != b.surahNumber
              ? a.surahNumber.compareTo(b.surahNumber)
              : a.ayahNumber.compareTo(b.ayahNumber),
        );
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bm = context.app.bookmarks;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('myBookmarks')),
        actions: [
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: context.tr('sortNewest'),
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _Sort.newest,
                child: Text(context.tr('sortNewest')),
              ),
              PopupMenuItem(
                value: _Sort.oldest,
                child: Text(context.tr('sortOldest')),
              ),
              PopupMenuItem(
                value: _Sort.surah,
                child: Text(context.tr('sortBySurah')),
              ),
            ],
          ),
        ],
      ),
      body: ContentWidth(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(bm.state),
            child: _body(context, bm),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, BookmarksController bm) {
    switch (bm.state) {
      case LoadState.loading:
        return const SkeletonList(count: 4);
      case LoadState.error:
        return AppErrorWidget(type: AppErrorType.unknown, onRetry: bm.load);
      case LoadState.empty:
        return EmptyState(
          icon: Icons.bookmark_border_rounded,
          title: context.tr('noBookmarks'),
          message: context.tr('noBookmarksMsg'),
          actionLabel: context.tr('exploreQuran'),
          onAction: () => AppNav.goToTab(context, 1),
        );
      case LoadState.loaded:
        final list = _apply(bm.items);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: context.tr('searchBookmarks'),
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.tr('noResults'),
                      message: context.tr('noResultsMsg'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _BookmarkTile(
                        key: ValueKey(list[i].key),
                        bookmark: list[i],
                      ),
                    ),
            ),
          ],
        );
    }
  }
}

/// Slides/fades in when added and collapses smoothly when removed.
class _BookmarkTile extends StatefulWidget {
  const _BookmarkTile({super.key, required this.bookmark});
  final Bookmark bookmark;

  @override
  State<_BookmarkTile> createState() => _BookmarkTileState();
}

class _BookmarkTileState extends State<_BookmarkTile>
    with SingleTickerProviderStateMixin {
  late final Future<Ayah?> _ayah;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _ayah = context.appRead.quran.findAyah(
      widget.bookmark.surahNumber,
      widget.bookmark.ayahNumber,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    if (_removing) return;
    _removing = true;
    HapticFeedback.lightImpact();
    await _c.reverse();
    if (!mounted) return;
    context.appRead.bookmarks.remove(
      widget.bookmark.surahNumber,
      widget.bookmark.ayahNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bookmark;
    final surah = SurahCatalog.byNumber(b.surahNumber);
    return SizeTransition(
      sizeFactor: _a,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _a,
        child: AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.surah,
            arguments: SurahArgs(b.surahNumber, b.ayahNumber),
          ),
          child: Row(
            children: [
              NumberBadge(b.ayahNumber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr('surah')} ${surah.englishName} ${b.key}',
                      style: AppTypography.body(color: context.cs.onSurface)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    FutureBuilder<Ayah?>(
                      future: _ayah,
                      builder: (_, snap) {
                        final a = snap.data;
                        if (a == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            a.englishTranslation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTypography.caption(color: context.mutedText),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.tr('removeBookmark'),
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _remove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
