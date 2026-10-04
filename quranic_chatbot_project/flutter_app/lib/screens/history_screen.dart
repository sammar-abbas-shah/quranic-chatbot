part of '../main.dart';

// ---------------------------------------------------------------------------
// Chat history screen.
// ---------------------------------------------------------------------------

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.tr('deleteConversationQ')),
            content: Text(ctx.tr('deleteConversationMsg')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.tr('delete')),
              ),
            ],
          ),
        ) ??
        false;
    if (ok && mounted) context.appRead.history.delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final h = context.app.history;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('history'))),
      body: ContentWidth(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(h.state),
            child: _body(context, h),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, HistoryController h) {
    switch (h.state) {
      case LoadState.loading:
        return const SkeletonList(count: 4);
      case LoadState.error:
        return AppErrorWidget(type: AppErrorType.unknown, onRetry: h.load);
      case LoadState.empty:
        return EmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: context.tr('noConversations'),
          message: context.tr('noConversationsMsg'),
          actionLabel: context.tr('startChat'),
          onAction: () {
            context.appRead.chat.newConversation();
            AppNav.goToTab(context, 2);
          },
        );
      case LoadState.loaded:
        final q = _query.trim().toLowerCase();
        final list = h.items
            .where((c) => q.isEmpty || c.title.toLowerCase().contains(q))
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: context.tr('searchConversations'),
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
                      itemBuilder: (_, i) {
                        final c = list[i];
                        return FadeSlideIn(
                          key: ValueKey(c.id),
                          enabled: i < 8,
                          delay: Duration(milliseconds: 50 * (i < 8 ? i : 0)),
                          child: AppCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            onTap: () {
                              context.appRead.chat.openConversation(c);
                              AppNav.goToTab(context, 2);
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textDirection: directionOf(c.title),
                                        style: AppTypography.body(
                                          color: context.cs.onSurface,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${relativeDate(context, c.updatedAt)} · ${c.messages.length} ${context.tr('messagesCount')}',
                                        style: AppTypography.caption(
                                          color: context.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: context.tr('delete'),
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                  onPressed: () => _confirmDelete(c.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
    }
  }
}
