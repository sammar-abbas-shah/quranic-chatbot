part of '../main.dart';

// ---------------------------------------------------------------------------
// Bookmarks state.
// ---------------------------------------------------------------------------

class BookmarksController extends ChangeNotifier {
  BookmarksController(this._service);
  final BookmarkService _service;

  LoadState state = LoadState.loading;
  List<Bookmark> items = [];

  Future<void> load() async {
    try {
      items = await _service.getAll();
      state = items.isEmpty ? LoadState.empty : LoadState.loaded;
    } catch (_) {
      state = LoadState.error;
    }
    notifyListeners();
  }

  bool isBookmarked(int s, int a) =>
      items.any((b) => b.surahNumber == s && b.ayahNumber == a);

  Future<void> toggle(int s, int a) async {
    if (isBookmarked(s, a)) {
      await _service.remove(s, a);
    } else {
      await _service.add(
        Bookmark(surahNumber: s, ayahNumber: a, createdAt: DateTime.now()),
      );
    }
    await load();
  }

  Future<void> remove(int s, int a) async {
    await _service.remove(s, a);
    await load();
  }

  Future<void> clear() async {
    await _service.clear();
    await load();
  }
}
