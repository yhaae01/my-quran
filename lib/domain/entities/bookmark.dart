enum BookmarkColor {
  red,
  green,
  yellow,
  blue;

  String get label => switch (this) {
    BookmarkColor.red => 'Merah',
    BookmarkColor.green => 'Hijau',
    BookmarkColor.yellow => 'Kuning',
    BookmarkColor.blue => 'Biru',
  };

  static BookmarkColor fromName(String? name) {
    return BookmarkColor.values.firstWhere(
      (color) => color.name == name,
      orElse: () => BookmarkColor.green,
    );
  }
}

class Bookmark {
  const Bookmark({
    required this.id,
    required this.surahName,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
    required this.color,
    required this.timestamp,
  });

  final String id;
  final String surahName;
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String translation;
  final BookmarkColor color;
  final DateTime timestamp;

  String get reference => '$surahName • Ayat $verseNumber';

  Bookmark copyWith({
    String? id,
    String? surahName,
    int? surahNumber,
    int? verseNumber,
    String? arabicText,
    String? translation,
    BookmarkColor? color,
    DateTime? timestamp,
  }) {
    return Bookmark(
      id: id ?? this.id,
      surahName: surahName ?? this.surahName,
      surahNumber: surahNumber ?? this.surahNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      arabicText: arabicText ?? this.arabicText,
      translation: translation ?? this.translation,
      color: color ?? this.color,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
