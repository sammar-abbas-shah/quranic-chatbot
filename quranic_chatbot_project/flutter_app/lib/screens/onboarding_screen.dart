part of '../main.dart';

// ---------------------------------------------------------------------------
// Welcome cards shown on first launch.
// ---------------------------------------------------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _pages = <(IconData, String)>[
    (Icons.menu_book_rounded, 'onb1'),
    (Icons.chat_bubble_outline_rounded, 'onb2'),
    (Icons.mic_none_rounded, 'onb3'),
    (Icons.graphic_eq_rounded, 'onb4'),
    (Icons.headphones_rounded, 'onb5'),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _finish() {
    context.appRead.settings.setFirstLaunchDone();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _page.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: last ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: last,
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(context.tr('skip')),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _index = i);
                  },
                  itemBuilder: (_, i) {
                    final (icon, key) = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.6, end: 1.0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.elasticOut,
                            builder: (_, v, child) =>
                                Transform.scale(scale: v, child: child),
                            child: Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    context.cs.primary.withOpacity(0.18),
                                    context.accentGold.withOpacity(0.12),
                                  ],
                                ),
                                border: Border.all(
                                  color: context.accentGold,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                icon,
                                size: 60,
                                color: context.cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            context.tr('${key}Title'),
                            textAlign: TextAlign.center,
                            style: AppTypography.heading(
                              size: 26,
                              color: context.cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('${key}Msg'),
                            textAlign: TextAlign.center,
                            style: AppTypography.body(
                              size: 16,
                              color: context.mutedText,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < _pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsetsDirectional.only(end: 6),
                            width: i == _index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? context.cs.primary
                                  : context.borderColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _next,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          context.tr(last ? 'getStarted' : 'next'),
                          key: ValueKey(last),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
