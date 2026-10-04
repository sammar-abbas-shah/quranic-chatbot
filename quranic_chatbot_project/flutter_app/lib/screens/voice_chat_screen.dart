part of '../main.dart';

// ---------------------------------------------------------------------------
// Voice chat screen.
// ---------------------------------------------------------------------------

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  late final VoiceChatController _voice;

  @override
  void initState() {
    super.initState();
    _voice = context.appRead.voice;
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final ok = await PermissionFlow.ensureMicrophone(context);
    if (!mounted) return;
    if (!ok) {
      _voice.failWith('err_microphone_msg');
      return;
    }
    await _voice.start();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _voice.disposeSession(); // silent: no notifyListeners while unmounting
    super.dispose();
  }

  String _label(BuildContext c, VoiceState s) {
    switch (s) {
      case VoiceState.idle:
        return c.tr('speakYourQuestion');
      case VoiceState.listening:
        return c.tr('listening');
      case VoiceState.processing:
        return c.tr('processing');
      case VoiceState.speaking:
        return c.tr('speaking');
      case VoiceState.error:
        return c.tr('tryAgain');
    }
  }

  String _hint(BuildContext c, VoiceState s) {
    switch (s) {
      case VoiceState.idle:
        return c.tr('voiceIdleHint');
      case VoiceState.listening:
        return c.tr('listeningHint');
      case VoiceState.processing:
        return c.tr('processingHint');
      case VoiceState.speaking:
        return c.tr('speakingHint');
      case VoiceState.error:
        return c.tr(_voice.errorKey ?? 'err_unknown_msg');
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.app.voice;
    final lang = context.app.settings.responseLanguage;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('voice'))),
      body: SafeArea(
        child: ContentWidth(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                VoiceOrb(state: v.state, animation: _pulse),
                Semantics(
                  liveRegion: true,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _label(context, v.state),
                      key: ValueKey(v.state),
                      textAlign: TextAlign.center,
                      style: AppTypography.heading(
                        size: 22,
                        color: context.cs.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hint(context, v.state),
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: context.mutedText),
                ),
                const SizedBox(height: 20),
                if (v.state == VoiceState.listening) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      formatDuration(v.elapsed),
                      style: AppTypography.heading(
                        size: 28,
                        color: context.cs.primary,
                      ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: v.transcript.isNotEmpty
                      ? AppCard(
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              v.transcript,
                              textDirection: directionOf(v.transcript),
                              style: styleForScript(
                                detectScript(v.transcript),
                                size: 20,
                                color: context.cs.onSurface,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                if (v.reply != null) ...[
                  const SizedBox(height: 16),
                  ChatBubble(message: v.reply!),
                ],
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(v.state),
                    child: _actions(context, v, lang),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, VoiceChatController v, String lang) {
    switch (v.state) {
      case VoiceState.listening:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await v.cancel();
                  if (mounted) Navigator.pop(context);
                },
                child: Text(context.tr('cancel')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: v.send,
                icon: const Icon(Icons.send_rounded),
                label: Text(context.tr('send')),
              ),
            ),
          ],
        );
      case VoiceState.processing:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: v.cancel,
            child: Text(context.tr('cancel')),
          ),
        );
      case VoiceState.speaking:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.appRead.tts.stop(),
            icon: const Icon(Icons.stop_rounded),
            label: Text(context.tr('stop')),
          ),
        );
      case VoiceState.error:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('goBack')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _start,
                child: Text(context.tr('tryAgain')),
              ),
            ),
          ],
        );
      case VoiceState.idle:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.mic_rounded),
            label: Text(
              context.tr(v.reply == null ? 'startListening' : 'askAnother'),
            ),
          ),
        );
    }
  }
}
