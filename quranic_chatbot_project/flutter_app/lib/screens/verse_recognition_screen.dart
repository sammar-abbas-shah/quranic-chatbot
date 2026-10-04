part of '../main.dart';

// ---------------------------------------------------------------------------
// Recite & Recognize screen.
// ---------------------------------------------------------------------------

class VerseRecognitionScreen extends StatefulWidget {
  const VerseRecognitionScreen({super.key});

  @override
  State<VerseRecognitionScreen> createState() => _VerseRecognitionScreenState();
}

class _VerseRecognitionScreenState extends State<VerseRecognitionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  late final RecognitionController _rec;

  @override
  void initState() {
    super.initState();
    _rec = context.appRead.recognition;
    // Always start from a clean state; defer to avoid notifying during build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _rec.reset());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _rec.disposeSession();
    context.appRead.audio.stop();
    super.dispose();
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    final ok = await PermissionFlow.ensureMicrophone(context);
    if (!mounted) return;
    if (!ok) {
      _rec.failWith(RecognitionErrorType.microphonePermission);
      return;
    }
    await _rec.start();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.app.recognition;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('recognize'))),
      body: SafeArea(
        child: ContentWidth(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween(begin: 0.97, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(r.stage),
              child: _stage(context, r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _center(List<Widget> children) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );

  Widget _stage(BuildContext context, RecognitionController r) {
    switch (r.stage) {
      case RecognitionStage.initial:
        return _center([
          Text(
            context.tr('reciteTitle'),
            textAlign: TextAlign.center,
            style: AppTypography.heading(size: 24, color: context.cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('reciteHint'),
            textAlign: TextAlign.center,
            style: AppTypography.body(size: 16, color: context.mutedText),
          ),
          const SizedBox(height: 24),
          PressScale(
            onTap: _start,
            child: VoiceOrb(state: VoiceState.idle, animation: _pulse),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.mic_rounded),
            label: Text(context.tr('startRecording')),
          ),
        ]);

      case RecognitionStage.recording:
        return _center([
          Semantics(
            liveRegion: true,
            child: Text(
              context.tr('listening'),
              style: AppTypography.heading(
                size: 24,
                color: context.cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatDuration(r.elapsed),
            style: AppTypography.heading(
              size: 36,
              color: context.cs.primary,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: 12),
          VoiceOrb(state: VoiceState.listening, animation: _pulse),
          Text(
            context.tr('recordingHint'),
            style: AppTypography.body(color: context.mutedText),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: r.stop,
            icon: const Icon(Icons.stop_rounded),
            label: Text(context.tr('stopRecording')),
          ),
          TextButton(
            onPressed: r.cancelRecording,
            child: Text(context.tr('cancel')),
          ),
        ]);

      case RecognitionStage.processing:
        return _center([
          VoiceOrb(state: VoiceState.processing, animation: _pulse),
          Semantics(
            liveRegion: true,
            child: Text(
              context.tr('analyzing'),
              textAlign: TextAlign.center,
              style: AppTypography.heading(
                size: 20,
                color: context.cs.onSurface,
              ),
            ),
          ),
        ]);

      case RecognitionStage.result:
        final res = r.result!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(child: SectionLabel(context.tr('yourRecitation'))),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: AppCard(
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    res.transcript,
                    textDirection: directionOf(res.transcript),
                    style: styleForScript(
                      detectScript(res.transcript),
                      size: 20,
                      color: context.cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: SectionLabel(context.tr('matchedVerse')),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: QuranAyahCard(ayah: res.ayah, showSurahHeader: true),
            ),
            // Only shown when the recognition service actually provides one.
            if (res.confidence != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${context.tr('confidence')}: ${(res.confidence! * 100).round()}%',
                  style: AppTypography.body(color: context.mutedText),
                ),
              ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.surah,
                        arguments: SurahArgs(
                          res.ayah.surahNumber,
                          res.ayah.ayahNumber,
                        ),
                      ),
                      child: Text(context.tr('viewInQuran')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: r.reset,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.tr('tryAgain')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case RecognitionStage.failure:
        final type = r.error ?? RecognitionErrorType.unknown;
        final perm = type == RecognitionErrorType.microphonePermission;
        return _center([
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.cs.error.withOpacity(0.10),
            ),
            child: Icon(
              perm ? Icons.mic_off_rounded : Icons.search_off_rounded,
              size: 48,
              color: context.cs.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('rec_${type.name}_title'),
            textAlign: TextAlign.center,
            style: AppTypography.heading(size: 22, color: context.cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('rec_${type.name}_msg'),
            textAlign: TextAlign.center,
            style: AppTypography.body(size: 16, color: context.mutedText),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: r.reset, child: Text(context.tr('tryAgain'))),
        ]);
    }
  }
}
