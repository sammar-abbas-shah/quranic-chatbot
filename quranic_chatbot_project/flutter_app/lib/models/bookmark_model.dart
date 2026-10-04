part of '../main.dart';

// ---------------------------------------------------------------------------
// Bookmark model.
// ---------------------------------------------------------------------------

class Bookmark {
  const Bookmark({
    required this.surahNumber,
    required this.ayahNumber,
    required this.createdAt,
  });
  final int surahNumber;
  final int ayahNumber;
  final DateTime createdAt;
  String get key => '$surahNumber:$ayahNumber';

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        surahNumber: j['surahNumber'] as int,
        ayahNumber: j['ayahNumber'] as int,
        createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
      );
}
