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
      expect(model.timestamp, sampleTimestamp);

      final restoredEntity = model.toEntity();
      expect(restoredEntity.id, sampleBookmark.id);
      expect(restoredEntity.surahName, sampleBookmark.surahName);
      expect(restoredEntity.surahNumber, sampleBookmark.surahNumber);
      expect(restoredEntity.verseNumber, sampleBookmark.verseNumber);
      expect(restoredEntity.arabicText, sampleBookmark.arabicText);
      expect(restoredEntity.translation, sampleBookmark.translation);
      expect(restoredEntity.timestamp, sampleBookmark.timestamp);
    });

    test('reference property returns formatted surah and ayah text', () {
      expect(sampleBookmark.reference, 'Al-Fatihah • Ayat 1');
    });

    test('copyWith properly updates specified fields while keeping others unchanged', () {
      final updatedBookmark = sampleBookmark.copyWith(
        verseNumber: 2,
        translation: 'Terjemahan baru.',
      );

      expect(updatedBookmark.id, sampleBookmark.id);
      expect(updatedBookmark.surahName, sampleBookmark.surahName);
      expect(updatedBookmark.verseNumber, 2);
      expect(updatedBookmark.translation, 'Terjemahan baru.');
      expect(updatedBookmark.reference, 'Al-Fatihah • Ayat 2');
    });

    test('exposes professional UI labels instead of colour names', () {
      expect(Bookmark.activeLabel, 'Penanda Terakhir');
      expect(Bookmark.savedLabel, 'Ayat Tersimpan');
    });

    test('repairs a stored bookmark with missing fields', () {
      const incomplete = BookmarkModel(id: 'broken', surahNumber: 2);

      final entity = incomplete.toEntity();

      expect(entity.surahName, 'Surah 2');
      expect(entity.arabicText, '');
      expect(entity.translation, '');
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
