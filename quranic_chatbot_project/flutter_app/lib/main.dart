// ============================================================================
//  QURANIC CHATBOT — Flutter app entry point
//
//  This file only does three things:
//    1. lists the packages the app uses (imports),
//    2. lists every source file that makes up the app (part directives),
//    3. contains main(), which opens the local database and starts the app.
//
//  Every other file under lib/ is a `part of` this library, so they share these
//  imports and can see each other's classes. See the handbook for a map of
//  what each folder contains:
//    app/       app root, dependency container, routes
//    models/    data classes
//    data/      built-in Quran data (Surah names, Juz positions, sample verses)
//    utils/     helper functions
//    services/  service contracts, mock + real implementations, audio, cache
//    state/     controllers (settings, chat, bookmarks, recognition, ...)
//    l10n/      UI text in English / Urdu / Arabic
//    theme/     colours, typography, the 12 themes
//    widgets/   reusable widgets
//    screens/   full-page screens
// ============================================================================

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'services.dart' as api;

part 'app/app.dart';
part 'app/routes.dart';
part 'models/audio_models.dart';
part 'models/bookmark_model.dart';
part 'models/chat_models.dart';
part 'models/enums.dart';
part 'models/quran_models.dart';
part 'models/recognition_models.dart';
part 'models/user_model.dart';
part 'data/featured_verses.dart';
part 'data/juz_catalog.dart';
part 'data/mock_quran_data.dart';
part 'data/surah_catalog.dart';
part 'utils/autoplay_helpers.dart';
part 'utils/helpers.dart';
part 'services/backend_services.dart';
part 'services/http_services.dart';
part 'services/just_audio_service.dart';
part 'services/local_storage_services.dart';
part 'services/mock_services.dart';
part 'services/recitation_cache.dart';
part 'services/service_interfaces.dart';
part 'state/bookmarks_controller.dart';
part 'state/chat_controller.dart';
part 'state/history_controller.dart';
part 'state/navigation_state.dart';
part 'state/quran_controller.dart';
part 'state/recognition_controller.dart';
part 'state/settings_controller.dart';
part 'state/voice_chat_controller.dart';
part 'l10n/strings.dart';
part 'theme/app_colors.dart';
part 'theme/app_theme.dart';
part 'theme/app_typography.dart';
part 'theme/theme_catalog.dart';
part 'widgets/action_widgets.dart';
part 'widgets/audio_widgets.dart';
part 'widgets/chat_widgets.dart';
part 'widgets/feedback_widgets.dart';
part 'widgets/ui_primitives.dart';
part 'widgets/verse_widgets.dart';
part 'screens/about_screen.dart';
part 'screens/auth_screens.dart';
part 'screens/ayah_screen.dart';
part 'screens/bookmarks_screen.dart';
part 'screens/chat_screen.dart';
part 'screens/history_screen.dart';
part 'screens/home_screen.dart';
part 'screens/juz_screen.dart';
part 'screens/main_shell.dart';
part 'screens/onboarding_screen.dart';
part 'screens/quran_list_screen.dart';
part 'screens/search_screen.dart';
part 'screens/settings_screen.dart';
part 'screens/splash_screen.dart';
part 'screens/surah_list_screen.dart';
part 'screens/surah_screen.dart';
part 'screens/verse_recognition_screen.dart';
part 'screens/voice_chat_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and open the offline Quran cache box before the app
  // starts, so HttpQuranService can use it from the first frame.
  await Hive.initFlutter();
  final cacheBox = await Hive.openBox('quran_cache');

  // Boxes used by local persistence: bookmarks, chat history, and the
  // first-launch/auth flags that drive app-flow routing (Splash ->
  // Onboarding -> Login/Signup -> Home). Opened once here so every service
  // and controller can use Hive.box(...) synchronously afterwards.
  await Hive.openBox('bookmarks_box');
  await Hive.openBox('history_box');
  await Hive.openBox('app_flags_box');
  await Hive.openBox('settings_box');

  // Unpack the bundled quran_offline.json asset into the cache once. Uses a
  // dedicated marker key (not 'all_surahs') so it still runs even if some
  // surahs were already cached from an earlier network fetch.
  if (!cacheBox.containsKey('offline_seeded_v1')) {
    try {
      final raw = await rootBundle.loadString('assets/quran_offline.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final surahs = data['surahs'] as List<dynamic>;
      final ayahs = data['ayahs'] as Map<String, dynamic>;
      await cacheBox.put('all_surahs', jsonEncode(surahs));
      for (final entry in ayahs.entries) {
        await cacheBox.put('surah_${entry.key}', jsonEncode(entry.value));
      }
      await cacheBox.put('offline_seeded_v1', true);
    } catch (e) {
      // Asset missing or malformed: the app still works, it will just fetch
      // Surahs from the network as usual instead of being offline-ready.
      debugPrint('Offline Quran asset not loaded: $e');
    }
  }

  runApp(const QuranicChatbotApp());
}
