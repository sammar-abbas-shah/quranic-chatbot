part of '../main.dart';

// ---------------------------------------------------------------------------
// Splash screen and start-up routing.
// ---------------------------------------------------------------------------

// ============================================================================
// 11. SCREENS
// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), _next);
  }

  void _next() {
    if (!mounted) return;
    final s = context.appRead.settings;
    // First launch: show the welcome cards, then Login/Signup.
    // Subsequent opens: skip straight to Home if already logged in,
    // otherwise straight to Login.
    final route = s.isFirstLaunch
        ? AppRoutes.onboarding
        : (s.isLoggedIn ? AppRoutes.home : AppRoutes.login);
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    final scale = Tween(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    // Derived from the active theme (not hardcoded green) so the splash
    // screen matches whichever theme is selected, including on first launch
    // before onboarding/login -- themeId is already loaded synchronously
    // from Hive by the time this builds.
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final accent = context.accentGold;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(bg, primary, 0.24)!,
              bg,
              Color.lerp(bg, Colors.black, context.isDark ? 0.18 : 0.0)!,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 104),
                  const SizedBox(height: 24),
                  Text(
                    'Quranic Chatbot',
                    style: AppTypography.heading(size: 28, color: onSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'القرآن الكريم',
                    style: AppTypography.arabicUi(size: 22, color: accent),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 96,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeInOut,
                      builder: (_, v, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 3,
                          color: accent,
                          backgroundColor: onSurface.withOpacity(0.12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
