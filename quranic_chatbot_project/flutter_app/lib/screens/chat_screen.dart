part of '../main.dart';

// ---------------------------------------------------------------------------
// AI chat screen.
// ---------------------------------------------------------------------------

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = 0;
  bool _lastGenerating = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    context.appRead.chat.send(text);
    _input.clear();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.app.chat;
    final settings = context.app.settings;

    if (chat.messages.length != _lastCount ||
        chat.isGenerating != _lastGenerating) {
      _lastCount = chat.messages.length;
      _lastGenerating = chat.isGenerating;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }

    final empty = chat.messages.isEmpty && !chat.isGenerating;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('assistantTitle')),
        actions: [
          IconButton(
            tooltip: context.tr('history'),
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
          ),
          IconButton(
            tooltip: context.tr('newChat'),
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: chat.newConversation,
          ),
        ],
      ),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${context.tr('responseLanguage')}:',
                    style: AppTypography.caption(color: context.mutedText),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: LanguageSelector(
                        value: settings.responseLanguage,
                        onChanged: settings.setResponseLanguage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: empty
                    ? _Welcome(key: const ValueKey('welcome'), onSelect: _send)
                    : ListView.builder(
                        key: const ValueKey('messages'),
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        itemCount:
                            chat.messages.length + (chat.isGenerating ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= chat.messages.length) {
                            return const _TypingBubble();
                          }
                          final m = chat.messages[i];
                          return ChatBubble(
                            key: ValueKey(m.id),
                            message: m,
                          );
                        },
                      ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: chat.hasError
                  ? Container(
                      width: double.infinity,
                      color: context.cs.error.withOpacity(0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: context.cs.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr('err_network_msg'),
                              style: AppTypography.caption(
                                color: context.cs.onSurface,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: chat.retry,
                            child: Text(context.tr('retry')),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            _InputBar(
              controller: _input,
              enabled: !chat.isGenerating,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({super.key, required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final keys = ['q1', 'q2', 'q3', 'q4'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          FadeSlideIn(child: const AppLogo(size: 68)),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              context.tr('askAssistant'),
              textAlign: TextAlign.center,
              style:
                  AppTypography.heading(size: 22, color: context.cs.onSurface),
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: Text(
              context.tr('askAssistantMsg'),
              textAlign: TextAlign.center,
              style: AppTypography.body(color: context.mutedText),
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < keys.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 200 + 70 * i),
              child: SuggestedQuestion(
                text: context.tr(keys[i]),
                onTap: () => onSelect(context.tr(keys[i])),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      duration: const Duration(milliseconds: 300),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          liveRegion: true,
          label: context.tr('generating'),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border.all(color: context.borderColor),
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(20),
                topEnd: Radius.circular(20),
                bottomStart: Radius.circular(5),
                bottomEnd: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TypingDots(),
                const SizedBox(width: 12),
                Text(
                  context.tr('generating'),
                  style: AppTypography.body(color: context.mutedText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: BorderSide(color: context.borderColor),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            VoiceButton(
              tooltip: context.tr('voice'),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.voiceChat),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                decoration: InputDecoration(
                  hintText: context.tr('typeMessage'),
                  border: pill,
                  enabledBorder: pill,
                  disabledBorder: pill,
                  focusedBorder: pill.copyWith(
                    borderSide:
                        BorderSide(color: context.cs.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, v, _) {
                final has = v.text.trim().isNotEmpty;
                return AnimatedScale(
                  scale: has && enabled ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: IconButton.filled(
                    tooltip: context.tr('send'),
                    onPressed:
                        enabled && has ? () => onSend(controller.text) : null,
                    icon: const Icon(Icons.send_rounded),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
