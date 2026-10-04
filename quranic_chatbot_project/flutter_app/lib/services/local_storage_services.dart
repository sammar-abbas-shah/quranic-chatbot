part of '../main.dart';

// ---------------------------------------------------------------------------
// Hive-backed and in-memory bookmark/history services.
// ---------------------------------------------------------------------------

/// Persists chat conversations (bookmarks' counterpart for chat) on-device
/// with Hive, so previous AI conversations are available offline and across
/// restarts. Each conversation is stored as a JSON string keyed by its id,
/// in the box opened in main().
class HiveHistoryService implements HistoryService {
  Box get _box => Hive.box('history_box');

  @override
  Future<List<ChatConversation>> getAll() async {
    final list = _box.values
        .map((v) => ChatConversation.fromJson(
            jsonDecode(v as String) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> save(ChatConversation c) async {
    await _box.put(c.id, jsonEncode(c.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

class InMemoryBookmarkService implements BookmarkService {
  final List<Bookmark> _items = [];

  @override
  Future<List<Bookmark>> getAll() async => [..._items];

  @override
  Future<void> add(Bookmark bookmark) async {
    if (_items.any((b) => b.key == bookmark.key)) return;
    _items.add(bookmark);
  }

  @override
  Future<void> remove(int surahNumber, int ayahNumber) async {
    _items.removeWhere(
      (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
    );
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}

/// Persists bookmarks on-device with Hive so they survive app restarts and
/// work fully offline. Each bookmark is stored as a JSON string, keyed by
/// "surah:ayah" (see [Bookmark.key]), in the box opened in main() -- the
/// same jsonEncode/jsonDecode convention main() already uses for the
/// offline Quran cache.
class HiveBookmarkService implements BookmarkService {
  Box get _box => Hive.box('bookmarks_box');

  @override
  Future<List<Bookmark>> getAll() async {
    return _box.values
        .map((v) => Bookmark.fromJson(
            jsonDecode(v as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> add(Bookmark bookmark) async {
    await _box.put(bookmark.key, jsonEncode(bookmark.toJson()));
  }

  @override
  Future<void> remove(int surahNumber, int ayahNumber) async {
    await _box.delete('$surahNumber:$ayahNumber');
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
