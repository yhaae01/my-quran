import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_quran/data/datasources/bookmark_local_data_source.dart';
import 'package:my_quran/data/models/bookmark_model.dart';
import 'package:my_quran/data/repositories/bookmark_repository_impl.dart';
import 'package:my_quran/domain/entities/bookmark.dart';

void main() {
  late Directory tempDir;
  late Box<BookmarkModel> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('my_quran_bookmark_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BookmarkModelAdapter());
    }
    box = await Hive.openBox<BookmarkModel>('bookmarks_test');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('persists, updates and deletes a bookmark through Hive', () async {
    final repository = BookmarkRepositoryImpl(BookmarkLocalDataSource(box));
    final bookmark = Bookmark(
      id: '1_1_1',
      surahName: 'Al-Fatihah',
      surahNumber: 1,
      verseNumber: 1,
      arabicText: 'بِسْمِ اللّٰهِ',
      translation: 'Dengan nama Allah.',
      timestamp: DateTime(2026, 11, 14, 9, 30),
    );

    await repository.saveBookmark(bookmark);
    var saved = await repository.getBookmarks();

    expect(saved, hasLength(1));
    expect(saved.single.translation, 'Dengan nama Allah.');
    expect(saved.single.reference, 'Al-Fatihah • Ayat 1');

    await repository.saveBookmark(
      bookmark.copyWith(translation: 'Terjemahan diperbarui.'),
    );
    saved = await repository.getBookmarks();

    expect(saved, hasLength(1));
    expect(saved.single.translation, 'Terjemahan diperbarui.');
    expect(saved.single.timestamp, bookmark.timestamp);

    await repository.deleteBookmark(bookmark.id);
    expect(await repository.getBookmarks(), isEmpty);
  });

  test('returns bookmarks newest first', () async {
    final repository = BookmarkRepositoryImpl(BookmarkLocalDataSource(box));
    final older = Bookmark(
      id: 'old',
      surahName: 'Al-Baqarah',
      surahNumber: 2,
      verseNumber: 1,
      arabicText: 'الٓمٓ',
      translation: 'Alif Lam Mim.',
      timestamp: DateTime(2026, 1, 1),
    );
    final newer = Bookmark(
      id: 'new',
      surahName: 'Al-Ikhlas',
      surahNumber: 112,
      verseNumber: 1,
      arabicText: 'قُلْ هُوَ اللّٰهُ أَحَدٌ',
      translation: 'Katakanlah, Dialah Allah Yang Maha Esa.',
      timestamp: DateTime(2026, 2, 1),
    );

    await box.clear();
    await repository.saveBookmark(older);
    await repository.saveBookmark(newer);
    final saved = await repository.getBookmarks();

    expect(saved.map((bookmark) => bookmark.id), ['new', 'old']);
  });
}
