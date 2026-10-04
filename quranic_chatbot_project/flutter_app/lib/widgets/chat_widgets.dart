part of '../main.dart';

// ---------------------------------------------------------------------------
// Chat bubble and typing indicator.
// ---------------------------------------------------------------------------

/// User = end side, Assistant = start side (mirrors automatically in RTL).
/// New messages ease in; old ones (e.g. from history) appear instantly.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxW = (MediaQuery.sizeOf(context).width * 0.86).clamp(0.0, 640.0);
    final paragraphs = message.text
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty);
    final textColor = isUser ? context.cs.onPrimary : context.cs.onSurface;
    final isFresh = DateTime.now().difference(message.time).inSeconds < 2;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                p.trim(),
                textDirection: directionOf(p),
                style: styleForScript(
                  detectScript(p),
                  size: 16,
                  color: textColor,
                ),
              ),
            ),
          ),
        if (!isUser && message.citations.isNotEmpty) ...[
          Text(
            context.tr('quranRefs'),
            style: AppTypography.caption(color: context.accentGold)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          for (final a in message.citations) VerseCitationCard(ayah: a),
        ],
      ],
    );

    return FadeSlideIn(
      enabled: isFresh,
      offset: 12,
      duration: const Duration(milliseconds: 380),
      child: Align(
        alignment: isUser
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.cs.primary,
                        Color.lerp(context.cs.primary, Colors.black, 0.18)!,
                      ],
                    )
                  : null,
              color: isUser ? null : context.cardColor,
              border: isUser ? null : Border.all(color: context.borderColor),
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(20),
                topEnd: const Radius.circular(20),
                bottomStart: Radius.circular(isUser ? 20 : 5),
                bottomEnd: Radius.circular(isUser ? 5 : 20),
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Three bouncing dots shown while the assistant is generating.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.cs.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (_) {
                final p = (_c.value + 1 - i * 0.18) % 1.0;
                final v = p < 0.5 ? math.sin(p * 2 * math.pi) : 0.0;
                return Transform.translate(
                  offset: Offset(0, -5 * v),
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.35 + 0.65 * v),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
