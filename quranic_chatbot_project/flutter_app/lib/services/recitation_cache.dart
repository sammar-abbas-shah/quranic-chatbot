part of '../main.dart';

// ---------------------------------------------------------------------------
// Saves recitation MP3s on the device so verses work offline after the first play.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------- Recitation cache
//
// Saves every verse recording the first time it is played, so it plays with
// no internet afterwards. Files live in the app's private support folder
// (not the temp folder, which Android may purge) and are named after the
// audio URL, so switching reciter/bitrate can never serve the wrong audio.

class RecitationCacheStats {
  const RecitationCacheStats(this.files, this.bytes);
  final int files;
  final int bytes;
}

class RecitationCache {
  RecitationCache._();
  static final RecitationCache instance = RecitationCache._();

  /// Bumped whenever the cache changes, so Settings can refresh its numbers.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final Map<String, Future<File>> _inflight = {};
  Directory? _dir;

  Future<Directory> _root() async {
    final existing = _dir;
    if (existing != null && await existing.exists()) return existing;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/recitations');
    await dir.create(recursive: true);
    return _dir = dir;
  }

  /// .../Alafasy_128kbps/002255.mp3  ->  Alafasy_128kbps_002255.mp3
  static String fileNameFor(String url) {
    final segs =
        Uri.parse(url).pathSegments.where((s) => s.isNotEmpty).toList();
    final tail = segs.length > 2 ? segs.sublist(segs.length - 2) : segs;
    final name = tail.join('_').replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return name.isEmpty ? '${url.hashCode}.mp3' : name;
  }

  /// The saved file for [url], or null if this verse hasn't been saved yet.
  Future<File?> cachedFile(String url) async {
    final f = File('${(await _root()).path}/${fileNameFor(url)}');
    if (await f.exists() && await f.length() > 0) return f;
    return null;
  }

  /// Returns the saved file, downloading it first if needed. Two taps on the
  /// same verse share one download. Throws if the download fails.
  Future<File> fetch(String url) {
    final running = _inflight[url];
    if (running != null) return running;
    final future = _download(url).whenComplete(() {
      _inflight.remove(url);
    });
    _inflight[url] = future;
    return future;
  }

  Future<File> _download(String url) async {
    final hit = await cachedFile(url);
    if (hit != null) return hit;

    final dir = await _root();
    final name = fileNameFor(url);
    final part = File('${dir.path}/$name.part');
    final dest = File('${dir.path}/$name');

    final res =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
      throw HttpException(
        'Audio download failed (HTTP ${res.statusCode})',
        uri: Uri.parse(url),
      );
    }
    // Write to a temp name first, then rename: a dropped connection or a
    // killed app can never leave a half-written file that looks complete.
    await part.writeAsBytes(res.bodyBytes, flush: true);
    await part.rename(dest.path);
    revision.value++;
    return dest;
  }

  Future<void> delete(String url) async {
    final f = File('${(await _root()).path}/${fileNameFor(url)}');
    if (await f.exists()) await f.delete();
    revision.value++;
  }

  Future<RecitationCacheStats> stats() async {
    final dir = await _root();
    var files = 0;
    var bytes = 0;
    await for (final e in dir.list()) {
      if (e is File && !e.path.endsWith('.part')) {
        files++;
        bytes += await e.length();
      }
    }
    return RecitationCacheStats(files, bytes);
  }

  Future<void> clear() async {
    final dir = await _root();
    await for (final e in dir.list()) {
      try {
        await e.delete(recursive: true);
      } catch (_) {}
    }
    revision.value++;
  }
}

String formatFileSize(int bytes) {
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(0)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / gb).toStringAsFixed(2)} GB';
}
