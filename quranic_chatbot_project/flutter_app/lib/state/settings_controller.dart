part of '../main.dart';

// ---------------------------------------------------------------------------
// All user settings and app-flow flags, persisted in Hive.
// ---------------------------------------------------------------------------

class SettingsController extends ChangeNotifier {
  static const reciters = ['Mishary Alafasy', 'Abdul Basit', 'Al-Husary'];
  static const speeds = [0.75, 1.0, 1.25, 1.5];

  Box get _box => Hive.box('settings_box');

  SettingsController() {
    // App-flow flags and reading/appearance settings are read synchronously
    // here: main() has already awaited Hive.openBox(...) for every box used
    // below, before this controller (and the rest of AppServices) is
    // constructed.
    final flags = Hive.box('app_flags_box');
    isFirstLaunch = flags.get('isFirstLaunch', defaultValue: true) as bool;
    isLoggedIn = flags.get('isLoggedIn', defaultValue: false) as bool;
    themeId = flags.get('themeId', defaultValue: 'system') as String;

    final box = _box;
    languageCode = box.get('languageCode', defaultValue: 'en') as String;
    arabicFontSize =
        (box.get('arabicFontSize', defaultValue: 28.0) as num).toDouble();
    showArabic = box.get('showArabic', defaultValue: true) as bool;
    showTranslation = box.get('showTranslation', defaultValue: true) as bool;
    translationLanguage =
        box.get('translationLanguage', defaultValue: 'en') as String;
    reciter = box.get('reciter', defaultValue: reciters.first) as String;
    playbackSpeed =
        (box.get('playbackSpeed', defaultValue: 1.0) as num).toDouble();
    autoPlay = box.get('autoPlay', defaultValue: false) as bool;
    responseLanguage =
        box.get('responseLanguage', defaultValue: 'en') as String;
    voiceResponses = box.get('voiceResponses', defaultValue: true) as bool;
    lastSurah = box.get('lastSurah') as int?;
    lastAyah = box.get('lastAyah') as int?;
    lastJuz = box.get('lastJuz') as int?;
  }

  /// 'system' follows the device's light/dark setting using the Classic
  /// look; any other value is one of AppThemeCatalog.all's ids and is used
  /// as-is regardless of device brightness. Persisted in Hive.
  late String themeId;
  late String languageCode;
  late double arabicFontSize;
  late bool showArabic;
  late bool showTranslation;
  late String translationLanguage; // en | ur | both
  late String reciter;
  late double playbackSpeed;
  late bool autoPlay;
  late String responseLanguage;
  late bool voiceResponses;

  /// True until the welcome/onboarding cards have been shown once. Persisted
  /// in Hive so it survives app restarts.
  late bool isFirstLaunch;

  /// True once the user has logged in (or signed up). Persisted in Hive so
  /// returning, already-logged-in users skip straight to Home.
  late bool isLoggedIn;

  /// "Continue Reading" target: updated both when a Surah/Juz screen is
  /// opened and continuously while the user scrolls through it, and
  /// persisted in Hive so it survives app restarts.
  int? lastSurah;
  int? lastAyah;
  int? lastJuz;

  bool get isRtl => languageCode != 'en';

  void _u(VoidCallback f) {
    f();
    notifyListeners();
  }

  void setThemeId(String v) {
    Hive.box('app_flags_box').put('themeId', v);
    _u(() => themeId = v);
  }

  void setLanguage(String v) {
    _box.put('languageCode', v);
    _u(() => languageCode = v);
  }

  void setArabicFontSize(double v) {
    _box.put('arabicFontSize', v);
    _u(() => arabicFontSize = v);
  }

  void setShowArabic(bool v) {
    _box.put('showArabic', v);
    _u(() => showArabic = v);
  }

  void setShowTranslation(bool v) {
    _box.put('showTranslation', v);
    _u(() => showTranslation = v);
  }

  void setTranslationLanguage(String v) {
    _box.put('translationLanguage', v);
    _u(() => translationLanguage = v);
  }

  void setReciter(String v) {
    _box.put('reciter', v);
    _u(() => reciter = v);
  }

  void setPlaybackSpeed(double v) {
    _box.put('playbackSpeed', v);
    _u(() => playbackSpeed = v);
  }

  void setAutoPlay(bool v) {
    _box.put('autoPlay', v);
    _u(() => autoPlay = v);
  }

  void setResponseLanguage(String v) {
    _box.put('responseLanguage', v);
    _u(() => responseLanguage = v);
  }

  void setVoiceResponses(bool v) {
    _box.put('voiceResponses', v);
    _u(() => voiceResponses = v);
  }

  /// Call once the welcome cards have been shown (or skipped).
  Future<void> setFirstLaunchDone() async {
    await Hive.box('app_flags_box').put('isFirstLaunch', false);
    _u(() => isFirstLaunch = false);
  }

  /// Call after a successful login/signup, or when logging out.
  Future<void> setLoggedIn(bool v) async {
    await Hive.box('app_flags_box').put('isLoggedIn', v);
    _u(() => isLoggedIn = v);
  }

  /// Called when a Surah reader is opened, and again as the user scrolls
  /// through it, so "Continue Reading" always points at the exact verse
  /// they last had on screen.
  void setLastRead(int surah, int ayah) {
    if (lastSurah == surah && lastAyah == ayah) return;
    _box.put('lastSurah', surah);
    _box.put('lastAyah', ayah);
    _u(() {
      lastSurah = surah;
      lastAyah = ayah;
    });
  }

  /// Same idea for the Para/Juz reader: remembers which Juz was last open.
  void setLastJuz(int juz) {
    if (lastJuz == juz) return;
    _box.put('lastJuz', juz);
    _u(() => lastJuz = juz);
  }

  Future<void> resetAll() async {
    // "Clear Local Data" signs the user out and sends them through
    // onboarding again on the next launch.
    await Hive.box('app_flags_box').put('isFirstLaunch', true);
    await Hive.box('app_flags_box').put('isLoggedIn', false);
    await Hive.box('app_flags_box').put('themeId', 'system');
    await _box.clear();
    _u(() {
      themeId = 'system';
      languageCode = 'en';
      arabicFontSize = 28;
      showArabic = true;
      showTranslation = true;
      translationLanguage = 'en';
      reciter = reciters.first;
      playbackSpeed = 1.0;
      autoPlay = false;
      responseLanguage = 'en';
      voiceResponses = true;
      isFirstLaunch = true;
      isLoggedIn = false;
      lastSurah = null;
      lastAyah = null;
      lastJuz = null;
    });
  }
}
