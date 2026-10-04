part of '../main.dart';

// ---------------------------------------------------------------------------
// Sample verses used by the mock services and as offline fallback.
// ---------------------------------------------------------------------------

/// SAMPLE DATA FOR UI DEVELOPMENT ONLY.
///
/// A handful of Ayahs so every screen can be exercised without a backend.
/// Before any release, replace this with a verified Quran source (Arabic
/// Uthmani text + reviewed English/Urdu translations) served by the backend.
/// English wording follows the Sahih International style; the Urdu lines are
/// sample translations and must be replaced with a reviewed translation.
class MockQuranData {
  MockQuranData._();

  static String _audio(int s, int a) =>
      'https://everyayah.com/data/Alafasy_128kbps/'
      '${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';

  static Ayah _a(int s, int a, String ar, String en, String ur) => Ayah(
        surahNumber: s,
        ayahNumber: a,
        arabicText: ar,
        englishTranslation: en,
        urduTranslation: ur,
        audioUrl: _audio(s, a),
      );

  static final Map<int, List<Ayah>> bySurah = {
    1: [
      _a(
        1,
        1,
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
        'اللہ کے نام سے جو بہت مہربان نہایت رحم والا ہے',
      ),
      _a(
        1,
        2,
        'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
        '[All] praise is [due] to Allah, Lord of the worlds.',
        'سب تعریف اللہ ہی کے لیے ہے جو تمام جہانوں کا پالنے والا ہے',
      ),
      _a(
        1,
        3,
        'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        'The Entirely Merciful, the Especially Merciful,',
        'بہت مہربان، نہایت رحم والا',
      ),
      _a(
        1,
        4,
        'مَٰلِكِ يَوْمِ ٱلدِّينِ',
        'Sovereign of the Day of Recompense.',
        'روزِ جزا کا مالک',
      ),
      _a(
        1,
        5,
        'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
        'It is You we worship and You we ask for help.',
        'ہم تیری ہی عبادت کرتے ہیں اور تجھ ہی سے مدد مانگتے ہیں',
      ),
      _a(
        1,
        6,
        'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ',
        'Guide us to the straight path -',
        'ہمیں سیدھے راستے پر چلا',
      ),
      _a(
        1,
        7,
        'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ',
        'The path of those upon whom You have bestowed favor, not of those who have earned [Your] anger or of those who are astray.',
        'ان لوگوں کا راستہ جن پر تو نے انعام کیا، نہ ان کا جن پر غضب ہوا اور نہ گمراہوں کا',
      ),
    ],
    2: [
      _a(
        2,
        153,
        'يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ ٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ ۚ إِنَّ ٱللَّهَ مَعَ ٱلصَّـٰبِرِينَ',
        'O you who have believed, seek help through patience and prayer. Indeed, Allah is with the patient.',
        'اے ایمان والو! صبر اور نماز سے مدد لو، بے شک اللہ صبر کرنے والوں کے ساتھ ہے',
      ),
    ],
    3: [
      _a(
        3,
        200,
        'يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ ٱصْبِرُوا۟ وَصَابِرُوا۟ وَرَابِطُوا۟ وَٱتَّقُوا۟ ٱللَّهَ لَعَلَّكُمْ تُفْلِحُونَ',
        'O you who have believed, persevere and endure and remain stationed and fear Allah that you may be successful.',
        'اے ایمان والو! صبر کرو، مقابلے میں ثابت قدم رہو، (سرحدوں پر) جمے رہو اور اللہ سے ڈرتے رہو تاکہ تم فلاح پاؤ',
      ),
    ],
    103: [
      _a(103, 1, 'وَٱلْعَصْرِ', 'By time,', 'زمانے کی قسم'),
      _a(
        103,
        2,
        'إِنَّ ٱلْإِنسَٰنَ لَفِى خُسْرٍ',
        'Indeed, mankind is in loss,',
        'بے شک انسان خسارے میں ہے',
      ),
      _a(
        103,
        3,
        'إِلَّا ٱلَّذِينَ ءَامَنُوا۟ وَعَمِلُوا۟ ٱلصَّـٰلِحَـٰتِ وَتَوَاصَوْا۟ بِٱلْحَقِّ وَتَوَاصَوْا۟ بِٱلصَّبْرِ',
        'Except for those who have believed and done righteous deeds and advised each other to truth and advised each other to patience.',
        'سوائے ان کے جو ایمان لائے اور نیک عمل کیے اور آپس میں حق کی نصیحت اور صبر کی تلقین کرتے رہے',
      ),
    ],
    108: [
      _a(
        108,
        1,
        'إِنَّآ أَعْطَيْنَٰكَ ٱلْكَوْثَرَ',
        'Indeed, We have granted you, [O Muhammad], al-Kawthar.',
        'بے شک ہم نے آپ کو کوثر عطا کی',
      ),
      _a(
        108,
        2,
        'فَصَلِّ لِرَبِّكَ وَٱنْحَرْ',
        'So pray to your Lord and sacrifice [to Him alone].',
        'پس آپ اپنے رب کے لیے نماز پڑھیں اور قربانی کریں',
      ),
      _a(
        108,
        3,
        'إِنَّ شَانِئَكَ هُوَ ٱلْأَبْتَرُ',
        'Indeed, your enemy is the one cut off.',
        'بے شک آپ کا دشمن ہی بے نام و نشان ہے',
      ),
    ],
    112: [
      _a(
        112,
        1,
        'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
        'Say, "He is Allah, [who is] One,',
        'کہہ دو کہ وہ اللہ ایک ہے',
      ),
      _a(
        112,
        2,
        'ٱللَّهُ ٱلصَّمَدُ',
        'Allah, the Eternal Refuge.',
        'اللہ بے نیاز ہے',
      ),
      _a(
        112,
        3,
        'لَمْ يَلِدْ وَلَمْ يُولَدْ',
        'He neither begets nor is born,',
        'نہ اس کی کوئی اولاد ہے اور نہ وہ کسی کی اولاد ہے',
      ),
      _a(
        112,
        4,
        'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
        'Nor is there to Him any equivalent."',
        'اور نہ کوئی اس کا ہمسر ہے',
      ),
    ],
  };

  static List<Ayah> get all => bySurah.values.expand((e) => e).toList();

  static Ayah? find(int surah, int ayah) {
    final list = bySurah[surah];
    if (list == null) return null;
    for (final a in list) {
      if (a.ayahNumber == ayah) return a;
    }
    return null;
  }
}
