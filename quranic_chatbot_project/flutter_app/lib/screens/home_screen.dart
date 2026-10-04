part of '../main.dart';

// ---------------------------------------------------------------------------
// Home screen.
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<Ayah?> _featured;

  @override
  void initState() {
    super.initState();
    _featured = context.appRead.quranService.getFeaturedAyah();
  }

  Widget _stagger(int i, Widget child) => FadeSlideIn(
        delay: Duration(milliseconds: 70 * i),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              _stagger(0, _header(context)),
              const SizedBox(height: 24),
              _stagger(1, _quickActions(context)),
              const SizedBox(height: 24),
              _stagger(2, _continueReading(context)),
              const SizedBox(height: 28),
              _stagger(3, _recent(context)),
              const SizedBox(height: 28),
              _stagger(4, _featuredSection(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const AppLogo(size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('greeting'),
                style: AppTypography.heading(
                  size: 24,
                  color: context.cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('greetingSub'),
                style: AppTypography.body(size: 15, color: context.mutedText),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: context.tr('searchQuran'),
          icon: const Icon(Icons.search_rounded),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
        ),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.menu_book_rounded, 'readQuran', () => AppNav.goToTab(context, 1)),
      (
        Icons.chat_bubble_outline_rounded,
        'askQuran',
        () => AppNav.goToTab(context, 2),
      ),
      (
        Icons.graphic_eq_rounded,
        'reciteVerse',
        () => Navigator.pushNamed(context, AppRoutes.verseRecognition),
      ),
      (
        Icons.bookmark_border_rounded,
        'navBookmarks',
        () => AppNav.goToTab(context, 3),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 560 ? 4 : 2;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (icon, key, onTap) in items)
              SizedBox(
                width: w,
                child: AppCard(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.cs.primary.withOpacity(0.20),
                              context.accentGold.withOpacity(0.14),
                            ],
                          ),
                        ),
                        child: Icon(icon, color: context.cs.primary),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.tr(key),
                        style: AppTypography.body(color: context.cs.onSurface)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _continueReading(BuildContext context) {
    final s = context.app.settings;
    final surahNo = s.lastSurah ?? 1;
    final ayahNo = s.lastAyah ?? 1;
    final surah = SurahCatalog.byNumber(surahNo);
    final fg = context.cs.onPrimary;
    final progress = (ayahNo / surah.ayahCount).clamp(0.0, 1.0);
    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.cs.primary,
          Color.lerp(context.cs.primary, Colors.black, 0.35)!,
        ],
      ),
      padding: const EdgeInsets.all(22),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.surah,
        arguments: SurahArgs(surahNo, ayahNo),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .tr(
                        s.lastSurah == null
                            ? 'startReading'
                            : 'continueReading',
                      )
                      .toUpperCase(),
                  style: AppTypography.caption(color: fg.withOpacity(0.75))
                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.tr('surah')} ${surah.englishName}',
                  style: AppTypography.heading(size: 22, color: fg),
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.tr('ayah')} $ayahNo / ${surah.ayahCount}',
                  style: AppTypography.body(color: fg.withOpacity(0.75)),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: fg.withOpacity(0.18),
                    valueColor: AlwaysStoppedAnimation(fg.withOpacity(0.9)),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: fg.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('continueAction'),
                        style: AppTypography.body(color: fg)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Icon(context.forwardIcon, size: 16, color: fg),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            surah.arabicName,
            style: AppTypography.arabicQuran(
              size: 34,
              color: fg.withOpacity(0.85),
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _recent(BuildContext context) {
    final h = context.app.history;
    final recent = h.items.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          context.tr('recentConversations'),
          trailing: TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
            child: Text(context.tr('seeAll')),
          ),
        ),
        if (h.state == LoadState.loading)
          const SizedBox(
            height: 120,
            child: SkeletonList(count: 2, itemHeight: 48),
          )
        else if (recent.isEmpty)
          Text(
            context.tr('noRecent'),
            style: AppTypography.body(color: context.mutedText),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: context.accentGold,
                    ),
                    title: Text(
                      recent[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: directionOf(recent[i].title),
                    ),
                    subtitle: Text(relativeDate(context, recent[i].updatedAt)),
                    trailing: Icon(context.forwardIcon, size: 18),
                    onTap: () {
                      context.appRead.chat.openConversation(recent[i]);
                      AppNav.goToTab(context, 2);
                    },
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _featuredSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.tr('featuredVerse')),
        FutureBuilder<Ayah?>(
          future: _featured,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 140,
                child: SkeletonList(count: 1, itemHeight: 130),
              );
            }
            final a = snap.data;
            if (a == null) return const SizedBox.shrink();
            return FadeSlideIn(
              child: VerseCitationCard(
                ayah: a,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.ayah,
                  arguments: SurahArgs(a.surahNumber, a.ayahNumber),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
