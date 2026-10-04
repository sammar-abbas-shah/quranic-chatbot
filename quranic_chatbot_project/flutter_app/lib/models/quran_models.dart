part of '../main.dart';

// ---------------------------------------------------------------------------
// Core Quran models: Surah, Ayah, Translation, VerseReference.
// ---------------------------------------------------------------------------

class Surah {
  const Surah({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.ayahCount,
    required this.revelationType,
  });

  final int number;
  final String arabicName;
  final String englishName;
  final int ayahCount;
  final RevelationType revelationType;
}

class Translation {
  const Translation({required this.languageCode, required this.text});
  final String languageCode; // 'en' | 'ur'
  final String text;
}

class Ayah {
  const Ayah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    required this.englishTranslation,
    required this.urduTranslation,
    this.audioUrl,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final String englishTranslation;
  final String urduTranslation;
  final String? audioUrl;

  String get key => '$surahNumber:$ayahNumber';

  Translation translation(String languageCode) => Translation(
        languageCode: languageCode,
        text: languageCode == 'ur' ? urduTranslation : englishTranslation,
      );

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'arabicText': arabicText,
        'englishTranslation': englishTranslation,
        'urduTranslation': urduTranslation,
        'audioUrl': audioUrl,
      };

  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
        surahNumber: j['surahNumber'] as int,
        ayahNumber: j['ayahNumber'] as int,
        arabicText: '${j['arabicText'] ?? ''}',
        englishTranslation: '${j['englishTranslation'] ?? ''}',
        urduTranslation: '${j['urduTranslation'] ?? ''}',
        audioUrl: j['audioUrl'] as String?,
      );
}

class VerseReference {
  const VerseReference(this.surahNumber, this.ayahNumber);
  final int surahNumber;
  final int ayahNumber;
  String get key => '$surahNumber:$ayahNumber';
}
