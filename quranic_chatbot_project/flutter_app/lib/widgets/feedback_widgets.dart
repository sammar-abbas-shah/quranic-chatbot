part of '../main.dart';

// ---------------------------------------------------------------------------
// Loading, skeleton, error, empty and offline widgets.
// ---------------------------------------------------------------------------

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: AppTypography.body(color: context.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder list shown while content loads.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 7, this.itemHeight = 72});
  final int count;
  final double itemHeight;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.borderColor.withOpacity(context.isDark ? 0.9 : 0.55);
    final hi = Color.lerp(context.borderColor, context.cs.onSurface, 0.10)!
        .withOpacity(context.isDark ? 0.9 : 0.35);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: widget.count,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => Container(
              height: widget.itemHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment(-2 + 4 * t, 0),
                  end: Alignment(-1 + 4 * t, 0),
                  colors: [base, hi, base],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum AppErrorType {
  network,
  server,
  authentication,
  microphone,
  audio,
  speechRecognition,
  verseRecognition,
  unknown,
}

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.type = AppErrorType.unknown,
    this.onRetry,
    this.onBack,
  });
  final AppErrorType type;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  IconData get _icon {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off_rounded;
      case AppErrorType.server:
        return Icons.cloud_off_rounded;
      case AppErrorType.authentication:
        return Icons.lock_outline_rounded;
      case AppErrorType.microphone:
        return Icons.mic_off_rounded;
      case AppErrorType.audio:
        return Icons.volume_off_rounded;
      case AppErrorType.speechRecognition:
        return Icons.record_voice_over_rounded;
      case AppErrorType.verseRecognition:
        return Icons.search_off_rounded;
      case AppErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.cs.error.withOpacity(0.10),
                ),
                child: Icon(_icon, size: 44, color: context.cs.error),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('err_${type.name}_title'),
                textAlign: TextAlign.center,
                style: AppTypography.heading(
                  size: 20,
                  color: context.cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('err_${type.name}_msg'),
                textAlign: TextAlign.center,
                style: AppTypography.body(color: context.mutedText),
              ),
              const SizedBox(height: 20),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('retry')),
                ),
              if (onBack != null)
                TextButton(
                  onPressed: onBack,
                  child: Text(context.tr('goBack')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.accentGold.withOpacity(0.10),
                ),
                child: Icon(icon, size: 44, color: context.accentGold),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.heading(
                  size: 20,
                  color: context.cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: context.mutedText),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 22),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.app.connectivity.isOffline;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: offline
          ? Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                color: context.cs.secondary.withOpacity(0.22),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 18,
                      color: context.cs.onSurface,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${context.tr('offlineTitle')} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: context.tr('offlineMsg')),
                          ],
                        ),
                        style: AppTypography.caption(
                          color: context.cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
