import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/data/models/bookmark_model.dart';
import 'package:my_quran/domain/entities/bookmark.dart';

void main() {
  group('Bookmark Model & Entity Unit Tests', () {
    final sampleTimestamp = DateTime(2026, 11, 14, 15, 30);

    final sampleBookmark = Bookmark(
      id: 'surah_1_ayah_1',
      surahName: 'Al-Fatihah',
      surahNumber: 1,
      verseNumber: 1,
      arabicText: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
      translation: 'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang.',
      color: BookmarkColor.green,
      timestamp: sampleTimestamp,
    );

    test('creates BookmarkModel from entity and converts back to entity', () {
      final model = BookmarkModel.fromEntity(sampleBookmark);

      expect(model.id, sampleBookmark.id);
      expect(model.surahName, sampleBookmark.surahName);
      expect(model.surahNumber, sampleBookmark.surahNumber);
      expect(model.verseNumber, sampleBookmark.verseNumber);
      expect(model.arabicText, sampleBookmark.arabicText);
      expect(model.translation, sampleBookmark.translation);
      expect(model.color, BookmarkColor.green);
      expect(model.timestamp, sampleTimestamp);

      final restoredEntity = model.toEntity();
      expect(restoredEntity.id, sampleBookmark.id);
      expect(restoredEntity.surahName, sampleBookmark.surahName);
      expect(restoredEntity.surahNumber, sampleBookmark.surahNumber);
      expect(restoredEntity.verseNumber, sampleBookmark.verseNumber);
      expect(restoredEntity.arabicText, sampleBookmark.arabicText);
      expect(restoredEntity.translation, sampleBookmark.translation);
      expect(restoredEntity.color, sampleBookmark.color);
      expect(restoredEntity.timestamp, sampleBookmark.timestamp);
    });

    test('reference property returns formatted surah and ayah text', () {
      expect(sampleBookmark.reference, 'Al-Fatihah • Ayat 1');
    });

    test('copyWith properly updates specified fields while keeping others unchanged', () {
      final updatedBookmark = sampleBookmark.copyWith(
        color: BookmarkColor.blue,
        verseNumber: 2,
      );

      expect(updatedBookmark.id, sampleBookmark.id);
      expect(updatedBookmark.surahName, sampleBookmark.surahName);
      expect(updatedBookmark.color, BookmarkColor.blue);
      expect(updatedBookmark.verseNumber, 2);
      expect(updatedBookmark.translation, sampleBookmark.translation);
      expect(updatedBookmark.reference, 'Al-Fatihah • Ayat 2');
    });

    test(
      'BookmarkColor.fromName parses known names and falls back to default',
      () {
        expect(BookmarkColor.fromName('red'), BookmarkColor.red);
        expect(BookmarkColor.fromName('green'), BookmarkColor.green);
        expect(BookmarkColor.fromName('yellow'), BookmarkColor.yellow);
        expect(BookmarkColor.fromName('blue'), BookmarkColor.blue);

        // Null or invalid name falls back to BookmarkColor.green
        expect(BookmarkColor.fromName(null), BookmarkColor.green);
        expect(BookmarkColor.fromName('purple'), BookmarkColor.green);
        expect(BookmarkColor.fromName(''), BookmarkColor.green);
      },
    );

    test('BookmarkColor returns Indonesian label correctly', () {
      expect(BookmarkColor.red.label, 'Merah');
      expect(BookmarkColor.green.label, 'Hijau');
      expect(BookmarkColor.yellow.label, 'Kuning');
      expect(BookmarkColor.blue.label, 'Biru');
    });

    test('repairs a stored bookmark with missing fields', () {
      const incomplete = BookmarkModel(id: 'broken', surahNumber: 2);

      final entity = incomplete.toEntity();

      expect(entity.surahName, 'Surah 2');
      expect(entity.arabicText, '');
      expect(entity.translation, '');
      expect(entity.color, BookmarkColor.green);
      expect(entity.hasTimestamp, isFalse);
      expect(entity.isNavigable, isFalse);
      expect(entity.title, 'Surah 2 - Ayat 0');
    });

    test('exposes informative title and navigation state', () {
      expect(sampleBookmark.title, 'Surah Al-Fatihah - Ayat 1');
      expect(sampleBookmark.isNavigable, isTrue);
      expect(sampleBookmark.hasTimestamp, isTrue);
      expect(sampleBookmark.arabicSnippet, sampleBookmark.arabicText);
    });
  });
}
