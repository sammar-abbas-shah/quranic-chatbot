part of '../main.dart';

// ---------------------------------------------------------------------------
// Chat models: ChatMessage and ChatConversation.
// ---------------------------------------------------------------------------

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.language = 'en',
    this.citations = const [],
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime time;
  final String language;
  final List<Ayah> citations;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'time': time.toIso8601String(),
        'language': language,
        'citations': citations.map((c) => c.toJson()).toList(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: '${j['id']}',
        text: '${j['text'] ?? ''}',
        isUser: j['isUser'] as bool? ?? false,
        time: DateTime.tryParse('${j['time']}') ?? DateTime.now(),
        language: '${j['language'] ?? 'en'}',
        citations: ((j['citations'] as List?) ?? const [])
            .map((c) => Ayah.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
      );
}

class ChatConversation {
  ChatConversation({
    required this.id,
    required this.title,
    required this.updatedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  final String id;
  String title;
  DateTime updatedAt;
  final List<ChatMessage> messages;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatConversation.fromJson(Map<String, dynamic> j) =>
      ChatConversation(
        id: '${j['id']}',
        title: '${j['title'] ?? ''}',
        updatedAt: DateTime.tryParse('${j['updatedAt']}') ?? DateTime.now(),
        messages: ((j['messages'] as List?) ?? const [])
            .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
      );
}
