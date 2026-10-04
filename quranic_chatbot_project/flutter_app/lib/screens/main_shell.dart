part of '../main.dart';

// ---------------------------------------------------------------------------
// Bottom-tab shell that hosts Home, Quran, Chat, Bookmarks, Settings.
// ---------------------------------------------------------------------------

/// Keeps every tab alive (IndexedStack) while cross-fading the active one.
class _TabStack extends StatefulWidget {
  const _TabStack({required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  State<_TabStack> createState() => _TabStackState();
}

class _TabStackState extends State<_TabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(_a);

  @override
  void didUpdateWidget(covariant _TabStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _c.forward(from: 0);
      // Switching tabs leaves whichever tab started any verse audio, so
      // stop it rather than let it keep playing silently in the background.
      context.appRead.audio.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          // Same wrapper types for every tab so element state is preserved.
          FadeTransition(
            opacity: i == widget.index
                ? _a
                : const AlwaysStoppedAnimation<double>(1.0),
            child: SlideTransition(
              position: i == widget.index
                  ? _slide
                  : const AlwaysStoppedAnimation<Offset>(Offset.zero),
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}

/// Bottom navigation with cross-fading tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    if (widget.initialTab != 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.appRead.nav.go(widget.initialTab),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.app.nav;
    return Scaffold(
      body: _TabStack(
        index: nav.index,
        children: const [
          HomeScreen(),
          QuranListScreen(),
          ChatScreen(),
          BookmarksScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OfflineBanner(),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: NavigationBar(
              selectedIndex: nav.index,
              onDestinationSelected: (i) {
                HapticFeedback.selectionClick();
                nav.go(i);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: context.tr('navHome'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: const Icon(Icons.menu_book_rounded),
                  label: context.tr('navQuran'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: const Icon(Icons.chat_bubble_rounded),
                  label: context.tr('navChat'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bookmark_border_rounded),
                  selectedIcon: const Icon(Icons.bookmark_rounded),
                  label: context.tr('navBookmarks'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings_rounded),
                  label: context.tr('navSettings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
