class Hadith {
  const Hadith({
    required this.book,
    required this.number,
    required this.arabic,
    required this.translation,
    this.slug,
  });

  final String book;
  final String? slug;
  final int number;
  final String arabic;
  final String translation;

  /// Human-friendly title / citation reference.
  /// E.g. "HR. Shahih Bukhari No. 1" or "HR. Bukhari No. 1"
  String get reference {
    final cleanBook = book.replaceFirst(
      RegExp(r'^(HR\.\s*|Hadits\s*)', caseSensitive: false),
      '',
    );
    return 'HR. $cleanBook No. $number';
  }

  Hadith copyWith({
    String? book,
    String? slug,
    int? number,
    String? arabic,
    String? translation,
  }) {
    return Hadith(
      book: book ?? this.book,
      slug: slug ?? this.slug,
      number: number ?? this.number,
      arabic: arabic ?? this.arabic,
      translation: translation ?? this.translation,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Hadith &&
            runtimeType == other.runtimeType &&
            book == other.book &&
            number == other.number &&
            arabic == other.arabic &&
            translation == other.translation;
  }

  @override
  int get hashCode => Object.hash(book, number, arabic, translation);
}
