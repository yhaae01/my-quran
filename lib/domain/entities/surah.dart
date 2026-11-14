import 'ayah.dart';

class Surah {
  const Surah({
    required this.number,
    required this.name,
    required this.latinName,
    required this.meaning,
    required this.verseCount,
    required this.revelation,
    required this.description,
  });

  final int number;
  final String name;
  final String latinName;
  final String meaning;
  final int verseCount;

  /// "Mekah" or "Madinah".
  final String revelation;
  final String description;
}

class SurahDetail {
  const SurahDetail({required this.surah, required this.ayahs});

  final Surah surah;
  final List<Ayah> ayahs;

  Ayah? ayahNumber(int number) {
    for (final ayah in ayahs) {
      if (ayah.number == number) return ayah;
    }
    return null;
  }
}
