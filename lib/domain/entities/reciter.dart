/// Reciters exposed by the equran.id partial-audio CDN.
///
/// The numeric ids match the `audio` object keys returned by the API, so an
/// ayah cached from any source can be mapped back to the user's choice.
class Reciter {
  const Reciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.cdnPath,
  });

  final String id;
  final String name;
  final String arabicName;

  /// Folder name on `cdn.equran.id/audio-partial`.
  final String cdnPath;

  static const Reciter abdullahAlJuhany = Reciter(
    id: '01',
    name: 'Abdullah Al-Juhany',
    arabicName: 'عبد الله الجهني',
    cdnPath: 'Abdullah-Al-Juhany',
  );

  static const Reciter abdulMuhsinAlQasim = Reciter(
    id: '02',
    name: 'Abdul Muhsin Al-Qasim',
    arabicName: 'عبد المحسن القاسم',
    cdnPath: 'Abdul-Muhsin-Al-Qasim',
  );

  static const Reciter abdurrahmanAsSudais = Reciter(
    id: '03',
    name: 'Abdurrahman As-Sudais',
    arabicName: 'عبد الرحمن السديس',
    cdnPath: 'Abdurrahman-as-Sudais',
  );

  static const Reciter ibrahimAlDossari = Reciter(
    id: '04',
    name: 'Ibrahim Al-Dossari',
    arabicName: 'إبراهيم الدوسري',
    cdnPath: 'Ibrahim-Al-Dossari',
  );

  static const Reciter misharyAlafasy = Reciter(
    id: '05',
    name: 'Mishary Rashid Alafasy',
    arabicName: 'مشاري راشد العفاسي',
    cdnPath: 'Misyari-Rasyid-Al-Afasi',
  );

  static const Reciter yasserAlDosari = Reciter(
    id: '06',
    name: 'Yasser Al-Dosari',
    arabicName: 'ياسر الدوسري',
    cdnPath: 'Yasser-Al-Dosari',
  );

  static const List<Reciter> all = [
    abdullahAlJuhany,
    abdulMuhsinAlQasim,
    abdurrahmanAsSudais,
    ibrahimAlDossari,
    misharyAlafasy,
    yasserAlDosari,
  ];

  static Reciter get defaultReciter => misharyAlafasy;

  static Reciter fromId(String? id) {
    for (final reciter in all) {
      if (reciter.id == id) return reciter;
    }
    return defaultReciter;
  }

  String get label => '$name · ${arabicName == '' ? '' : arabicName}'.trim();

  String audioUrlFor(int surahNumber, int ayahNumber) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    return 'https://cdn.equran.id/audio-partial/$cdnPath/$surah$ayah.mp3';
  }

  @override
  bool operator ==(Object other) => other is Reciter && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
