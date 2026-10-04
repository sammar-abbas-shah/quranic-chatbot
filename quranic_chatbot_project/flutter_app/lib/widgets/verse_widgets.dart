part of '../main.dart';

// ---------------------------------------------------------------------------
// Verse cards (QuranAyahCard), translation card, citation card, highlighted text.
// ---------------------------------------------------------------------------

/// Text with case-insensitive highlighting of [query].
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    this.query,
    required this.style,
    this.textDirection,
    this.textAlign = TextAlign.start,
  });
  final String text;
  final String? query;
  final TextStyle style;
  final TextDirection? textDirection;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isEmpty) {
      return Text(
        text,
        style: style,
        textDirection: textDirection,
        textAlign: textAlign,
      );
    }
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + q.length),
          style: TextStyle(
            backgroundColor: context.accentGold.withOpacity(0.3),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = idx + q.length;
    }
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textDirection: textDirection,
      textAlign: textAlign,
    );
  }
}

/// One translation block (English LTR / Urdu RTL).
class TranslationCard extends StatelessWidget {
  const TranslationCard({
    super.key,
    required this.languageCode,
    required this.text,
    this.query,
  });
  final String languageCode;
  final String text;
  final String? query;

  @override
  Widget build(BuildContext context) {
    final isUrdu = languageCode == 'ur';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(isUrdu ? 'urdu' : 'english').toUpperCase(),
          style: AppTypography.caption(color: context.accentGold)
              .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: HighlightedText(
            text,
            query: query,
            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            style: AppTypography.forLanguage(
              languageCode,
              size: isUrdu ? 18 : 16,
              color: context.cs.onSurface.withOpacity(0.88),
            ).copyWith(height: isUrdu ? 2.0 : 1.6),
          ),
        ),
      ],
    );
  }
}

/// Small ornamental divider between Arabic text and translations.
class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.accentGold.withOpacity(0.5);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: c)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(width: 6, height: 6, color: context.accentGold),
            ),
          ),
          Expanded(child: Divider(color: c)),
        ],
      ),
    );
  }
}

/// The main Ayah block used in the reader, detail and recognition screens.
class QuranAyahCard extends StatefulWidget {
  const QuranAyahCard({
    super.key,
    required this.ayah,
    this.showSurahHeader = false,
    this.highlight = false,
  });
  final Ayah ayah;
  final bool showSurahHeader;
  final bool highlight;

  @override
  State<QuranAyahCard> createState() => _QuranAyahCardState();
}

class _QuranAyahCardState extends State<QuranAyahCard> {
  bool? _ar;
  bool? _en;
  bool? _ur;

  String _shareText() {
    final a = widget.ayah;
    final name = SurahCatalog.byNumber(a.surahNumber).englishName;
    return '${a.arabicText}\n\n${a.englishTranslation}\n\n${a.urduTranslation}\n\n— Surah $name (${a.key})';
  }

  Future<void> _onMenu(String v) async {
    switch (v) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: _shareText()));
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('copied'))));
        break;
      case 'share':
        await Clipboard.setData(ClipboardData(text: _shareText()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Copied. Add the share_plus package to open the share sheet.',
            ),
          ),
        );
        break;
      case 'ask':
        context.appRead.chat.startWithAyah(widget.ayah);
        AppNav.goToTab(context, 2);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.app.settings;
    final a = widget.ayah;
    final showAr = _ar ?? settings.showArabic;
    final showEn = _en ??
        (settings.showTranslation && settings.translationLanguage != 'ur');
    final showUr = _ur ??
        (settings.showTranslation && settings.translationLanguage != 'en');
    final surah = SurahCatalog.byNumber(a.surahNumber);

    Widget chip(String label, bool on, ValueChanged<bool> set) => FilterChip(
          label: Text(label),
          selected: on,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          onSelected: (v) {
            HapticFeedback.selectionClick();
            setState(() => set(v));
          },
        );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              NumberBadge(a.ayahNumber, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: widget.showSurahHeader
                    ? Text(
                        '${context.tr('surah')} ${surah.englishName} · ${a.key}',
                        style: AppTypography.body(color: context.cs.onSurface)
                            .copyWith(fontWeight: FontWeight.w600),
                      )
                    : const SizedBox.shrink(),
              ),
              BookmarkButton(
                surahNumber: a.surahNumber,
                ayahNumber: a.ayahNumber,
              ),
              PopupMenuButton<String>(
                tooltip: context.tr('more'),
                onSelected: _onMenu,
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'copy', child: Text(context.tr('copy'))),
                  PopupMenuItem(
                    value: 'share',
                    child: Text(context.tr('share')),
                  ),
                  PopupMenuItem(value: 'ask', child: Text(context.tr('askAi'))),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              chip(context.tr('arabic'), showAr, (v) => _ar = v),
              chip(context.tr('english'), showEn, (v) => _en = v),
              chip(context.tr('urdu'), showUr, (v) => _ur = v),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showAr)
                  Padding(
                    padding: const EdgeInsets.only(top: 14, right: 4, left: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        a.arabicText,
                        textDirection: TextDirection.rtl,
                        style: AppTypography.arabicQuran(
                          size: settings.arabicFontSize,
                          color: context.cs.onSurface,
                        ).copyWith(height: 2.15),
                      ),
                    ),
                  ),
                if (showAr && (showEn || showUr)) const _OrnamentDivider(),
                if (!showAr && (showEn || showUr)) const SizedBox(height: 12),
                if (showEn)
                  TranslationCard(
                    languageCode: 'en',
                    text: a.englishTranslation,
                  ),
                if (showEn && showUr) const SizedBox(height: 10),
                if (showUr)
                  TranslationCard(languageCode: 'ur', text: a.urduTranslation),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AudioPlayerWidget(
            track: AudioTrack(
              id: a.key,
              url: a.audioUrl ?? '',
              title: '${surah.englishName} ${a.key}',
            ),
          ),
        ],
      );

    // Only this thin wrapper rebuilds as playback position ticks -- `content`
    // above is passed through untouched, so the (much heavier) translation
    // text/chips don't get rebuilt several times a second.
    return ValueListenableBuilder<PlaybackState>(
      valueListenable: context.appRead.audio.state,
      builder: (context, audioState, child) {
        final playingHere = audioState.trackId == a.key &&
            (audioState.status == PlaybackStatus.playing ||
                audioState.status == PlaybackStatus.loading ||
                (audioState.status == PlaybackStatus.paused &&
                    audioState.position > Duration.zero));
        return AppCard(
          highlight: widget.highlight || playingHere,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          child: child!,
        );
      },
      child: content,
    );
  }
}

/// Tappable citation card shown whenever the assistant references a verse.
class VerseCitationCard extends StatelessWidget {
  const VerseCitationCard({super.key, required this.ayah, this.onTap});
  final Ayah ayah;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surah = SurahCatalog.byNumber(ayah.surahNumber);
    return AppCard(
      margin: const EdgeInsets.only(top: 10),
      onTap: onTap ??
          () => Navigator.pushNamed(
                context,
                AppRoutes.surah,
                arguments: SurahArgs(ayah.surahNumber, ayah.ayahNumber),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: context.accentGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.tr('surah')} ${surah.englishName} ${ayah.key}',
                  style: AppTypography.body(color: context.cs.onSurface)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Text(
              ayah.arabicText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicQuran(
                size: 22,
                color: context.cs.onSurface,
              ).copyWith(height: 1.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ayah.englishTranslation,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(color: context.mutedText, size: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                context.tr('viewAyah'),
                style: AppTypography.body(
                  color: context.cs.primary,
                  size: 14,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Icon(context.forwardIcon, size: 16, color: context.cs.primary),
            ],
          ),
        ],
      ),
    );
  }
}
