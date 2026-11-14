import 'package:hive/hive.dart';

import '../../domain/entities/bookmark.dart';

/// Hive representation of a bookmark. Kept separate from the domain entity so
/// storage details never leak into the rest of the app.
///
/// Every field except the id is nullable: entries written by older builds (or
/// partially corrupted boxes) must not crash the bookmark screen. [toEntity]
/// repairs missing values with readable fallbacks.
class BookmarkModel {
  const BookmarkModel({
    required this.id,
    this.surahName,
    this.surahNumber,
    this.verseNumber,
    this.arabicText,
    this.translation,
    this.color,
    this.timestamp,
  });

  final String id;
  final String? surahName;
  final int? surahNumber;
  final int? verseNumber;
  final String? arabicText;
  final String? translation;
  final BookmarkColor? color;
  final DateTime? timestamp;

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
    final surah = surahNumber ?? 0;
    final verse = verseNumber ?? 0;
    final storedName = surahName?.trim() ?? '';
    final savedAt = timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
    final storedId = id.trim();

    return Bookmark(
      id: storedId.isEmpty
          ? '${surah}_${verse}_${savedAt.millisecondsSinceEpoch}'
          : storedId,
      surahName: storedName.isNotEmpty
          ? storedName
          : (surah > 0 ? 'Surah $surah' : 'Surah tidak dikenal'),
      surahNumber: surah,
      verseNumber: verse,
      arabicText: arabicText ?? '',
      translation: translation ?? '',
      color: color ?? BookmarkColor.green,
      timestamp: savedAt,
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
      ..writeString(obj.surahName ?? '')
      ..writeInt(obj.surahNumber ?? 0)
      ..writeInt(obj.verseNumber ?? 0)
      ..writeString(obj.arabicText ?? '')
      ..writeString(obj.translation ?? '')
      ..writeString((obj.color ?? BookmarkColor.green).name)
      ..writeInt(
        (obj.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0))
            .millisecondsSinceEpoch,
      );
  }
}
