import '../../domain/entities/hadith.dart';

class HadithModel {
  const HadithModel({
    required this.book,
    required this.number,
    required this.arab,
    required this.id,
    this.slug,
    this.rawi,
  });

  final String book;
  final String? slug;
  final int number;
  final String arab;
  final String id;
  final String? rawi;

  factory HadithModel.fromJson(
    Map<String, dynamic> json, {
    String defaultBook = 'Hadis',
  }) {
    return HadithModel(
      book: json['book'] as String? ?? json['name'] as String? ?? defaultBook,
      slug: json['slug'] as String?,
      number: (json['number'] as num?)?.toInt() ?? 0,
      arab: json['arab'] as String? ?? json['arabic'] as String? ?? '',
      id: json['id'] as String? ?? json['translation'] as String? ?? '',
      rawi: json['rawi'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      if (slug != null) 'slug': slug,
      'number': number,
      if (rawi != null && rawi!.isNotEmpty) 'rawi': rawi,
      'arab': arab,
      'id': id,
    };
  }

  Hadith toEntity() {
    return Hadith(
      book: book,
      slug: slug,
      number: number,
      arabic: arab,
      translation: id,
      rawi: rawi,
    );
  }

  factory HadithModel.fromEntity(Hadith entity) {
    return HadithModel(
      book: entity.book,
      slug: entity.slug,
      number: entity.number,
      arab: entity.arabic,
      id: entity.translation,
      rawi: entity.rawi,
    );
  }
}
