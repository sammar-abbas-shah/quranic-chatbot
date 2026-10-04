part of '../main.dart';

// ---------------------------------------------------------------------------
// Chat conversation state.
// ---------------------------------------------------------------------------

class ChatController extends ChangeNotifier {
  ChatController(this._chat, this._history, this._settings);
  final ChatService _chat;
  final HistoryController _history;
  final SettingsController _settings;

  ChatConversation? current;
  bool isGenerating = false;
  bool hasError = false;

  List<ChatMessage> get messages => current?.messages ?? const [];

  void newConversation() {
    current = null;
    hasError = false;
    isGenerating = false;
    notifyListeners();
  }

  void openConversation(ChatConversation c) {
    current = c;
    hasError = false;
    notifyListeners();
  }

  Future<void> startWithAyah(Ayah a) {
    newConversation();
    final name = SurahCatalog.byNumber(a.surahNumber).englishName;
    return send('Explain Surah $name, Ayah ${a.ayahNumber} (${a.key}).');
  }

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || isGenerating) return;
    final now = DateTime.now();
    current ??= ChatConversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: t.length > 40 ? '${t.substring(0, 40)}…' : t,
      updatedAt: now,
    );
    current!.messages.add(
      ChatMessage(
        id: '${now.microsecondsSinceEpoch}u',
        text: t,
        isUser: true,
        time: now,
      ),
    );
    await _requestReply(t);
  }

  Future<void> retry() async {
    final last = messages.lastWhere(
      (m) => m.isUser,
      orElse: () =>
          ChatMessage(id: '', text: '', isUser: true, time: DateTime.now()),
    );
    if (last.text.isEmpty || isGenerating) return;
    await _requestReply(last.text);
  }

  Future<void> _requestReply(String text) async {
    isGenerating = true;
    hasError = false;
    notifyListeners();
    final conv = current;
    try {
      final reply = await _chat.sendMessage(
        text: text,
        languageCode: _settings.responseLanguage,
      );
      conv?.messages.add(reply);
      conv?.updatedAt = DateTime.now();
      if (conv != null) await _history.save(conv);
    } catch (_) {
      hasError = true;
    }
    isGenerating = false;
    notifyListeners();
  }
}
