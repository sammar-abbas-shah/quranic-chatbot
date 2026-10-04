part of '../main.dart';

// ---------------------------------------------------------------------------
// App root: MaterialApp/theme wiring, navigation observer, AppScope (dependency access) and AppServices (which service implementation is used).
// ---------------------------------------------------------------------------

// ============================================================ 1. APP ROOT

class QuranicChatbotApp extends StatefulWidget {
  const QuranicChatbotApp({super.key});

  @override
  State<QuranicChatbotApp> createState() => _QuranicChatbotAppState();
}

class _QuranicChatbotAppState extends State<QuranicChatbotApp> {
  final AppServices _services = AppServices();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: _services,
      child: AnimatedBuilder(
        animation: _services.settings,
        builder: (context, _) {
          final s = _services.settings;
          // 'system' follows the device's light/dark setting with the
          // Classic look; any specific themeId (including 'classicLight'/
          // 'classicDark') is pinned regardless of device brightness.
          final ThemeData light;
          final ThemeData dark;
          final ThemeMode mode;
          if (s.themeId == 'system') {
            light = AppTheme.build(AppThemeCatalog.classicLight);
            dark = AppTheme.build(AppThemeCatalog.classicDark);
            mode = ThemeMode.system;
          } else {
            final fixed = AppTheme.build(AppThemeCatalog.byId(s.themeId));
            light = fixed;
            dark = fixed;
            mode = ThemeMode.light;
          }
          return MaterialApp(
            title: 'Quranic Chatbot',
            debugShowCheckedModeBanner: false,
            theme: light,
            darkTheme: dark,
            themeMode: mode,
            // Smooth cross-fade when switching themes.
            themeAnimationDuration: const Duration(milliseconds: 350),
            themeAnimationCurve: Curves.easeInOut,
            builder: (context, child) {
              final theme = Theme.of(context);
              final dark = theme.brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: (dark
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark)
                    .copyWith(
                  systemNavigationBarColor: theme.scaffoldBackgroundColor,
                  systemNavigationBarDividerColor: Colors.transparent,
                ),
                // RTL comes from Flutter's Directionality (never reversed strings).
                child: Directionality(
                  textDirection:
                      s.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            navigatorObservers: [AudioStopObserver(_services.audio)],
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}

/// Gives every widget access to the app's controllers and rebuilds
/// dependents whenever any controller changes.
/// Stops verse audio whenever a full screen is popped (back button, swipe
/// back, popUntil...). Only PageRoutes count, so opening/closing bottom
/// sheets or dialogs never interrupts playback.
class AudioStopObserver extends NavigatorObserver {
  AudioStopObserver(this._audio);
  final AudioService _audio;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _audio.stop();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _audio.stop();
  }
}

class AppScope extends InheritedNotifier<Listenable> {
  AppScope({super.key, required this.services, required super.child})
      : super(notifier: services.listenable);

  final AppServices services;

  /// Subscribes to changes (use inside build).
  static AppServices of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  /// No subscription (use in initState / event handlers).
  static AppServices read(BuildContext c) =>
      c.getInheritedWidgetOfExactType<AppScope>()!.services;
}

/// Composition root. Swap the Mock* classes for real implementations here.
class AppServices {
  // ---- Backend wiring (your services.dart) ----
  final api.HttpQuranService httpQuran = api.HttpQuranService();
  final api.HttpChatService httpChat = api.HttpChatService();

  /// Surahs come from your backend; everything your HttpQuranService doesn't
  /// expose yet falls back to the built-in sample data.
  late final QuranService quranService =
      BackendQuranService(httpQuran, MockQuranService());
  late final ChatService chatService =
      BackendChatService(httpChat, quranService);
  late final SpeechRecognitionService sttService =
      HttpSpeechRecognitionService(httpChat);
  final TextToSpeechService tts = MockTextToSpeechService();
  late final VerseRecognitionService verseService =
      HttpVerseRecognitionService(httpChat, quranService);
  // Real recitation player (just_audio). MockAudioService is kept above for
  // UI experiments/tests but is no longer used.
  final AudioService audio = JustAudioService();
  // Hive-backed: bookmarks and chat history persist locally and work
  // offline. Swap back to InMemoryBookmarkService()/MockHistoryService() if
  // you ever need the old in-memory/sample behaviour for UI experiments.
  final BookmarkService bookmarkService = HiveBookmarkService();
  final HistoryService historyService = HiveHistoryService();

  late final SettingsController settings = SettingsController();
  late final QuranController quran = QuranController(quranService)
    ..loadSurahs();
  late final BookmarksController bookmarks = BookmarksController(
    bookmarkService,
  )..load();
  late final HistoryController history = HistoryController(historyService)
    ..load();
  late final ChatController chat = ChatController(
    chatService,
    history,
    settings,
  );
  late final VoiceChatController voice = VoiceChatController(
    sttService,
    tts,
    chat,
    settings,
  );
  late final RecognitionController recognition = RecognitionController(
    verseService,
  );
  final NavController nav = NavController();
  final ConnectivityController connectivity = ConnectivityController();

  late final Listenable listenable = Listenable.merge([
    settings,
    quran,
    bookmarks,
    history,
    chat,
    voice,
    recognition,
    nav,
    connectivity,
  ]);
}

extension AppContext on BuildContext {
  AppServices get app => AppScope.of(this);
  AppServices get appRead => AppScope.read(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get cs => Theme.of(this).colorScheme;
  Color get mutedText => cs.onSurfaceVariant;
  Color get borderColor => cs.outline;
  Color get cardColor => cs.surface;
  Color get accentGold => cs.secondary;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
  IconData get forwardIcon =>
      isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded;
  String tr(String key) => S.t(app.settings.languageCode, key);
}
