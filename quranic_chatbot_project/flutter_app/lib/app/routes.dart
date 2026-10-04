part of '../main.dart';

// ---------------------------------------------------------------------------
// Named routes, route arguments and the page transition.
// ---------------------------------------------------------------------------

// ============================================================================
// 12. ROUTES
// ============================================================================

class SurahArgs {
  const SurahArgs(this.surahNumber, [this.initialAyah]);
  final int surahNumber;
  final int? initialAyah;
}

class JuzArgs {
  const JuzArgs(this.juzNumber);
  final int juzNumber;
}

/// Soft fade + short slide transition used for every screen.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fadeOnly = false,
  }) : super(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 340),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, anim, secondary, child) {
            final curved = anim.drive(CurveTween(curve: Curves.easeOutCubic));
            if (fadeOnly) return FadeTransition(opacity: curved, child: child);
            final dir =
                Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.07 * dir, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const quran = '/quran';
  static const chat = '/chat';
  static const bookmarks = '/bookmarks';
  static const settings = '/settings';
  static const surah = '/surah';
  static const ayah = '/ayah';
  static const juz = '/juz';
  static const search = '/search';
  static const voiceChat = '/voice-chat';
  static const verseRecognition = '/verse-recognition';
  static const history = '/history';
  static const about = '/about';
  static const backendTest = '/backend-test';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    Widget page;
    var fadeOnly = false;
    switch (s.name) {
      case splash:
        page = const SplashScreen();
        fadeOnly = true;
        break;
      case onboarding:
        page = const OnboardingScreen();
        fadeOnly = true;
        break;
      case login:
        page = const LoginScreen();
        fadeOnly = true;
        break;
      case signup:
        page = const SignupScreen();
        break;
      case home:
        page = const MainShell(initialTab: 0);
        fadeOnly = true;
        break;
      case quran:
        page = const MainShell(initialTab: 1);
        break;
      case chat:
        page = const MainShell(initialTab: 2);
        break;
      case bookmarks:
        page = const MainShell(initialTab: 3);
        break;
      case settings:
        page = const MainShell(initialTab: 4);
        break;
      case surah:
        page = SurahScreen(args: s.arguments as SurahArgs);
        break;
      case ayah:
        page = AyahScreen(args: s.arguments as SurahArgs);
        break;
      case juz:
        page = JuzScreen(args: s.arguments as JuzArgs);
        break;
      case search:
        page = const SearchScreen();
        break;
      case voiceChat:
        page = const VoiceChatScreen();
        break;
      case verseRecognition:
        page = const VerseRecognitionScreen();
        break;
      case history:
        page = const HistoryScreen();
        break;
      case about:
        page = const AboutScreen();
        break;
      case backendTest:
        page = Builder(builder: (ctx) {
          final svc = ctx.appRead;
          return SurahListScreen(
            quranService: svc.httpQuran,
            chatService: svc.httpChat,
          );
        });
        break;
      default:
        page = const MainShell(initialTab: 0);
        fadeOnly = true;
    }
    return AppPageRoute<dynamic>(
      settings: s,
      fadeOnly: fadeOnly,
      builder: (_) => page,
    );
  }
}
