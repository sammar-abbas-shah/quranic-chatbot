part of '../main.dart';

// ---------------------------------------------------------------------------
// Helpers shared by the Surah and Juz readers for Auto Play (next verse, prefetch, follow-scroll).
// ---------------------------------------------------------------------------

// ---------------------------------------------------------- Auto Play helpers

/// Index of the first verse after [from] that has audio, or null at the end.
int? _nextPlayableIndex(List<Ayah> list, int from) {
  for (var i = from + 1; i < list.length; i++) {
    if ((list[i].audioUrl ?? '').isNotEmpty) return i;
  }
  return null;
}

/// Downloads the next verse's recitation in the background while the current
/// one plays, so Auto Play can start it with no gap.
void _prefetchRecitation(String? url) {
  if (url == null || url.isEmpty) return;
  unawaited(
    RecitationCache.instance
        .fetch(url)
        .then<void>((_) {}, onError: (Object _) {}),
  );
}

void _showAudioErrorSnack(BuildContext context, Object e) {
  if (!context.mounted) return;
  final msg = context.tr('err_audio_msg');
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(kDebugMode ? '$msg\n$e' : msg),
        duration: Duration(seconds: kDebugMode ? 10 : 4),
      ),
    );
}

/// Scrolls the lazy list so the card registered under [target] in [keys] is
/// on screen. The card may not be built yet (ListView.builder only builds
/// what is near the viewport), so this nudges the list a screen at a time
/// towards it until it exists, then eases it into view.
/// [stillWanted] lets the caller abort (screen closed / another verse tapped).
Future<void> _followListItem({
  required ScrollController controller,
  required Map<int, GlobalKey> keys,
  required int target,
  required bool Function() stillWanted,
}) async {
  for (var attempt = 0; attempt < 12; attempt++) {
    if (!stillWanted() || !controller.hasClients) return;
    final ctx = keys[target]?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
      return;
    }
    int? hi;
    for (final e in keys.entries) {
      if (e.value.currentContext == null) continue;
      hi = hi == null ? e.key : math.max(hi, e.key);
    }
    final forward = hi == null || target > hi;
    final pos = controller.position;
    final step = pos.viewportDimension * 0.8;
    final dest = (forward ? pos.pixels + step : pos.pixels - step)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent)
        .toDouble();
    if (dest == pos.pixels) return;
    controller.jumpTo(dest);
    await WidgetsBinding.instance.endOfFrame;
  }
}
