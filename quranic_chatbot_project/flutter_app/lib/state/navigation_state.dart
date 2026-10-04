part of '../main.dart';

// ---------------------------------------------------------------------------
// Navigation, connectivity and microphone-permission helpers.
// ---------------------------------------------------------------------------

class NavController extends ChangeNotifier {
  int index = 0;
  void go(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}

class AppNav {
  AppNav._();

  /// 0 Home, 1 Quran, 2 Chat, 3 Bookmarks, 4 Settings.
  static void goToTab(BuildContext context, int index) {
    context.appRead.nav.go(index);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

class ConnectivityController extends ChangeNotifier {
  /// Hook: call setOffline(true/false) from connectivity_plus later.
  bool isOffline = false;
  void setOffline(bool v) {
    if (v == isOffline) return;
    isOffline = v;
    notifyListeners();
  }
}

/// Simulated microphone permission flow (explain first, then ask).
/// Replace the body with permission_handler for the real Android prompt.
class PermissionFlow {
  PermissionFlow._();

  /// Explains why the mic is needed BEFORE asking, then triggers the real
  /// OS permission prompt via the record package (hasPermission() requests
  /// it if not already granted).
  static Future<bool> ensureMicrophone(BuildContext context) async {
    final probe = AudioRecorder();
    try {
      if (await probe.hasPermission()) return true;
      if (!context.mounted) return false;

      final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.mic_rounded),
              title: Text(ctx.tr('micAccessTitle')),
              content: Text(ctx.tr('micAccessMsg')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(ctx.tr('notNow')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(ctx.tr('allow')),
                ),
              ],
            ),
          ) ??
          false;
      if (!proceed) return false;
      return await probe.hasPermission();
    } finally {
      probe.dispose();
    }
  }
}
