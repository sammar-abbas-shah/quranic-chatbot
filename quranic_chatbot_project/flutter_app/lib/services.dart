// ============================================================================
//  services.dart — the app's HTTP layer (talks to the FastAPI backend)
//
//  main.dart imports this file as `api` (see `import 'services.dart' as api;`).
//  The rest of the app never calls the network directly: the wrappers in
//  lib/services/backend_services.dart and lib/services/http_services.dart use
//  the classes below.
//
//  >>> BEFORE YOU RUN THE APP: set kBackendBaseUrl to your own Vercel URL. <<<
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

/// Address of the deployed backend, WITHOUT a trailing slash.
/// Example: 'https://my-quran-backend.vercel.app'
const String kBackendBaseUrl = 'https://YOUR-PROJECT.vercel.app';

Uri _uri(String path, [Map<String, String>? query]) {
  final base = kBackendBaseUrl.endsWith('/')
      ? kBackendBaseUrl.substring(0, kBackendBaseUrl.length - 1)
      : kBackendBaseUrl;
  return Uri.parse('$base$path').replace(queryParameters: query);
}

/// Decodes a JSON response, or throws with the status code and body included
/// (the app recognises codes like 400 / 404 and texts like `no_match` in the
/// message to show friendly errors).
dynamic _decode(http.Response res, String what) {
  final body = utf8.decode(res.bodyBytes, allowMalformed: true);
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw HttpException('$what failed: ${res.statusCode} $body');
  }
  return jsonDecode(body);
}

// ---------------------------------------------------------------- Quran data

/// Surahs, verses, Juz and search. Quran text never changes, so results are
/// stored in the Hive box `quran_cache` and reused (this is also what makes
/// the bundled offline Quran work without internet).
class HttpQuranService {
  Box<dynamic> get _cache => Hive.box('quran_cache');

  List<dynamic>? _fromCache(String key) {
    try {
      final raw = _cache.get(key);
      if (raw is String) {
        final data = jsonDecode(raw);
        if (data is List && data.isNotEmpty) return data;
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> _getList(
    String path,
    String cacheKey, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final cached = _fromCache(cacheKey);
    if (cached != null) return cached;

    final res = await http.get(_uri(path)).timeout(timeout);
    final data = _decode(res, 'GET $path');
    if (data is! List) {
      throw const FormatException('Unexpected response from the server');
    }
    try {
      await _cache.put(cacheKey, jsonEncode(data));
    } catch (_) {}
    return data;
  }

  /// GET /surahs
  Future<List<dynamic>> getSurahs() => _getList('/surahs', 'all_surahs');

  /// GET /surahs/{id}/ayahs
  Future<List<dynamic>> getAyahs(int surahId) =>
      _getList('/surahs/$surahId/ayahs', 'surah_$surahId');

  /// GET /juz/{id}
  Future<List<dynamic>> getJuz(int juzId) => _getList(
        '/juz/$juzId',
        'juz_$juzId',
        timeout: const Duration(seconds: 45),
      );

  /// GET /search?q=...
  Future<List<dynamic>> search(String query) async {
    final res = await http
        .get(_uri('/search', {'q': query}))
        .timeout(const Duration(seconds: 30));
    final data = _decode(res, 'GET /search');
    return data is List ? data : <dynamic>[];
  }
}

// ------------------------------------------------- Chat, speech, recognition

class HttpChatService {
  /// POST /chat  ->  {"text": "...", "citations": ["2:255", ...]}
  Future<Map<String, dynamic>> sendChatMessage(
    String text, {
    String language = 'en',
  }) async {
    final res = await http
        .post(
          _uri('/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': text, 'language': language}),
        )
        .timeout(const Duration(seconds: 60));
    final data = _decode(res, 'POST /chat');
    if (data is! Map) {
      throw const FormatException('Unexpected response from the server');
    }
    return Map<String, dynamic>.from(data);
  }

  /// POST /stt  (multipart file)  ->  {"text": "..."}
  Future<String> speechToText(File file) async {
    final data = await _upload('/stt', file);
    return '${data['text'] ?? ''}'.trim();
  }

  /// POST /recognize  (multipart file)  ->  {transcript, confidence, ayah{...}}
  Future<Map<String, dynamic>> recognizeRecitation(File file) =>
      _upload('/recognize', file);

  Future<Map<String, dynamic>> _upload(String path, File file) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);
    final data = _decode(res, 'POST $path');
    if (data is! Map) {
      throw const FormatException('Unexpected response from the server');
    }
    return Map<String, dynamic>.from(data);
  }
}
