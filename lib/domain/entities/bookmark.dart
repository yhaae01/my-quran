class Bookmark {
  const Bookmark({
    required this.id,
    required this.surahName,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
    required this.timestamp,
  });

  /// Professional label used across the bookmark UI instead of colour names.
  static const String activeLabel = 'Penanda Terakhir';
  static const String savedLabel = 'Ayat Tersimpan';

  final String id;
  final String surahName;
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String translation;
  final DateTime timestamp;

  String get reference => '$displaySurahName • Ayat $verseNumber';

  /// Card title, e.g. "Surah Al-Baqarah - Ayat 255". The fallback name
  /// already starts with "Surah", so it is not prefixed twice.
  String get title {
    final name = displaySurahName;
    final label = name.startsWith('Surah ') ? name : 'Surah $name';
    return '$label - Ayat $verseNumber';
  }

  String get displaySurahName {
    final name = surahName.trim();
    if (name.isNotEmpty) return name;
    return surahNumber > 0 ? 'Surah $surahNumber' : 'Surah tidak dikenal';
  }

  /// A bookmark without a valid surah/ayah cannot be opened in the reader.
  bool get isNavigable => surahNumber > 0 && verseNumber > 0;

  /// Stored timestamps of repaired entries fall back to the Unix epoch.
  bool get hasTimestamp => timestamp.millisecondsSinceEpoch > 0;

  String get arabicSnippet => arabicText.trim();

  Bookmark copyWith({
    String? id,
    String? surahName,
    int? surahNumber,
    int? verseNumber,
    String? arabicText,
    String? translation,
    DateTime? timestamp,
  }) {
    return Bookmark(
      id: id ?? this.id,
      surahName: surahName ?? this.surahName,
      surahNumber: surahNumber ?? this.surahNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      arabicText: arabicText ?? this.arabicText,
      translation: translation ?? this.translation,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
