part of '../main.dart';

// ---------------------------------------------------------------------------
// Chat history state.
// ---------------------------------------------------------------------------

class HistoryController extends ChangeNotifier {
  HistoryController(this._service);
  final HistoryService _service;

  LoadState state = LoadState.loading;
  List<ChatConversation> items = [];

  Future<void> load() async {
    try {
      items = await _service.getAll();
      state = items.isEmpty ? LoadState.empty : LoadState.loaded;
    } catch (_) {
      state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> save(ChatConversation c) async {
    await _service.save(c);
    await load();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await load();
  }

  Future<void> clear() async {
    await _service.clear();
    await load();
  }
}
