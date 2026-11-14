/// Number of verses in every surah, 1..114 (Kufi count).
const List<int> surahVerseCounts = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, //
  123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
  112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
  34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
  54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
  60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
  14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
  28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
  29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
  15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
  11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
  5, 4, 5, 6,
];

/// Total number of verses in the Qur'an.
const int totalQuranVerses = 6236;

/// Number of verses that come before the given surah.
int versesBeforeSurah(int surahNumber) {
  final surah = surahNumber.clamp(1, surahVerseCounts.length);
  var total = 0;
  for (var index = 0; index < surah - 1; index++) {
    total += surahVerseCounts[index];
  }
  return total;
}

/// 1-based position of a verse in the canonical order of the whole Qur'an.
int cumulativeVerseNumber(int surahNumber, int ayahNumber) {
  final surah = surahNumber.clamp(1, surahVerseCounts.length);
  final ayah = ayahNumber.clamp(1, surahVerseCounts[surah - 1]);
  return versesBeforeSurah(surah) + ayah;
}

/// How far one reader has reached in the Qur'an.
///
/// Progress is measured in verses so members who read long and short surahs
/// still compare fairly on the challenge leaderboard.
class ReadingProgress {
  const ReadingProgress({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.updatedAt,
  });

  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final DateTime updatedAt;

  /// Position of the last verse reached, counted from the start of the Qur'an.
  int get versesRead => cumulativeVerseNumber(surahNumber, ayahNumber);

  double get ratio => (versesRead / totalQuranVerses).clamp(0.0, 1.0);

  int get percent => (ratio * 100).round();

  bool get isComplete => versesRead >= totalQuranVerses;

  String get reference => '$surahName • Ayat $ayahNumber';

  ReadingProgress copyWith({
    int? surahNumber,
    int? ayahNumber,
    String? surahName,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      surahName: surahName ?? this.surahName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'surah_name': surahName,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static ReadingProgress? fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return null;
    final surah = map['surah_number'];
    final ayah = map['ayah_number'];
    if (surah is! num || ayah is! num) return null;
    final updatedAt = DateTime.tryParse(map['updated_at'] as String? ?? '');
    return ReadingProgress(
      surahNumber: surah.toInt(),
      ayahNumber: ayah.toInt(),
      surahName: map['surah_name'] as String? ?? 'Surah ${surah.toInt()}',
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
