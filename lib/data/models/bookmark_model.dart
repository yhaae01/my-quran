import 'package:hive/hive.dart';

import '../../domain/entities/bookmark.dart';

/// Hive representation of a bookmark. Kept separate from the domain entity so
/// storage details never leak into the rest of the app.
class BookmarkModel {
  const BookmarkModel({
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

  factory BookmarkModel.fromEntity(Bookmark bookmark) {
    return BookmarkModel(
      id: bookmark.id,
      surahName: bookmark.surahName,
      surahNumber: bookmark.surahNumber,
      verseNumber: bookmark.verseNumber,
      arabicText: bookmark.arabicText,
      translation: bookmark.translation,
      color: bookmark.color,
      timestamp: bookmark.timestamp,
    );
  }

  Bookmark toEntity() {
    return Bookmark(
      id: id,
      surahName: surahName,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      arabicText: arabicText,
      translation: translation,
      color: color,
      timestamp: timestamp,
    );
  }
}

/// Hand-written adapter: no build_runner step is needed to run the app.
class BookmarkModelAdapter extends TypeAdapter<BookmarkModel> {
  @override
  final int typeId = 0;

  @override
  BookmarkModel read(BinaryReader reader) {
    final version = reader.readByte();
    switch (version) {
      case 1:
        return BookmarkModel(
          id: reader.readString(),
          surahName: reader.readString(),
          surahNumber: reader.readInt(),
          verseNumber: reader.readInt(),
          arabicText: reader.readString(),
          translation: reader.readString(),
          color: BookmarkColor.fromName(reader.readString()),
          timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
        );
      default:
        throw HiveError('Versi data penanda tidak dikenal: $version');
    }
  }

  @override
  void write(BinaryWriter writer, BookmarkModel obj) {
    writer
      ..writeByte(1)
      ..writeString(obj.id)
      ..writeString(obj.surahName)
      ..writeInt(obj.surahNumber)
      ..writeInt(obj.verseNumber)
      ..writeString(obj.arabicText)
      ..writeString(obj.translation)
      ..writeString(obj.color.name)
      ..writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}
