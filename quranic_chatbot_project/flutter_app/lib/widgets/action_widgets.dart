part of '../main.dart';

// ---------------------------------------------------------------------------
// Language selector, suggestion chips, bookmark and voice buttons.
// ---------------------------------------------------------------------------

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 'en', label: Text('English')),
        ButtonSegment(value: 'ur', label: Text('اردو')),
        ButtonSegment(value: 'ar', label: Text('العربية')),
      ],
      selected: {value},
      onSelectionChanged: (s) {
        HapticFeedback.selectionClick();
        onChanged(s.first);
      },
    );
  }
}

class SuggestedQuestion extends StatelessWidget {
  const SuggestedQuestion({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: context.accentGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(color: context.cs.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.north_east_rounded, size: 18, color: context.cs.primary),
        ],
      ),
    );
  }
}

/// Bookmark toggle with a springy pop when the state changes.
class BookmarkButton extends StatelessWidget {
  const BookmarkButton({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });
  final int surahNumber;
  final int ayahNumber;

  @override
  Widget build(BuildContext context) {
    final saved = context.app.bookmarks.isBookmarked(surahNumber, ayahNumber);
    return IconButton(
      tooltip: context.tr(saved ? 'removeBookmark' : 'addBookmark'),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.elasticOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          key: ValueKey(saved),
          color: saved ? context.accentGold : null,
        ),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        context.appRead.bookmarks.toggle(surahNumber, ayahNumber);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(
                context.tr(saved ? 'bookmarkRemoved' : 'bookmarkAdded'),
              ),
            ),
          );
      },
    );
  }
}

class VoiceButton extends StatelessWidget {
  const VoiceButton({super.key, required this.onPressed, this.tooltip});
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip ?? context.tr('voice'),
      onPressed: onPressed,
      icon: const Icon(Icons.mic_rounded),
    );
  }
}

/// Animated microphone indicator with a distinct look for every state.
class VoiceOrb extends StatelessWidget {
  const VoiceOrb({
    super.key,
    required this.state,
    required this.animation,
    this.size = 160,
  });
  final VoiceState state;
  final Animation<double> animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color =
        state == VoiceState.error ? context.cs.error : context.cs.primary;
    final active =
        state == VoiceState.listening || state == VoiceState.speaking;
    final core = size * 0.66;

    IconData icon;
    switch (state) {
      case VoiceState.idle:
        icon = Icons.mic_none_rounded;
        break;
      case VoiceState.listening:
        icon = Icons.mic_rounded;
        break;
      case VoiceState.processing:
        icon = Icons.graphic_eq_rounded;
        break;
      case VoiceState.speaking:
        icon = Icons.volume_up_rounded;
        break;
      case VoiceState.error:
        icon = Icons.mic_off_rounded;
        break;
    }

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          return SizedBox(
            width: size * 1.25,
            height: size * 1.25,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  for (final phase in [0.0, 0.5])
                    Builder(
                      builder: (_) {
                        final p = (t + phase) % 1.0;
                        return Opacity(
                          opacity: (1 - p) * 0.7,
                          child: Container(
                            width: core * (1 + p * 0.6),
                            height: core * (1 + p * 0.6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 2),
                            ),
                          ),
                        );
                      },
                    ),
                if (state == VoiceState.processing)
                  SizedBox(
                    width: core + 12,
                    height: core + 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: color,
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: core,
                  height: core,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state == VoiceState.idle
                        ? color.withOpacity(0.12)
                        : (state == VoiceState.processing
                            ? color.withOpacity(0.16)
                            : color),
                    border: state == VoiceState.idle
                        ? Border.all(color: color.withOpacity(0.5), width: 1.5)
                        : null,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.35),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ]
                        : const [],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      icon,
                      key: ValueKey(state),
                      size: core * 0.45,
                      color: (state == VoiceState.idle ||
                              state == VoiceState.processing)
                          ? color
                          : context.cs.onPrimary,
                    ),
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
