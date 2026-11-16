import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/domain/entities/bookmark.dart';
import 'package:my_quran/domain/entities/reading_progress.dart';
import 'package:my_quran/domain/repositories/bookmark_repository.dart';
import 'package:my_quran/domain/repositories/reading_progress_repository.dart';
import 'package:my_quran/presentation/providers/bookmark_providers.dart';
import 'package:my_quran/presentation/providers/core_providers.dart';
import 'package:my_quran/presentation/providers/reading_progress_providers.dart';

class _FakeBookmarkRepository implements BookmarkRepository {
  final List<Bookmark> saved = [];

  @override
  Future<List<Bookmark>> getBookmarks() async => List.of(saved);

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {
    saved.add(bookmark);
  }

  @override
  Future<void> deleteBookmark(String id) async {
    saved.removeWhere((bookmark) => bookmark.id == id);
  }
}

class _FakeReadingProgressRepository implements ReadingProgressRepository {
  final List<ReadingProgress> saved = [];

  @override
  ReadingProgress? load() => null;

  @override
  Future<void> save(ReadingProgress progress) async {
    saved.add(progress);
  }
}

Bookmark _bookmark(int surah, int verse) {
  return Bookmark(
    id: '${surah}_$verse',
    surahName: 'Surah $surah',
    surahNumber: surah,
    verseNumber: verse,
    arabicText: '﴿$verse﴾',
    translation: 'Terjemahan $verse',
    timestamp: DateTime(2026, 11, 15),
  );
}

ProviderContainer _container(
  _FakeBookmarkRepository bookmarks,
  _FakeReadingProgressRepository progress,
) {
  final container = ProviderContainer(
    overrides: [
      bookmarkRepositoryProvider.overrideWithValue(bookmarks),
      readingProgressRepositoryProvider.overrideWithValue(progress),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('saving a new bookmark replaces the previous one', () async {
    final bookmarkRepository = _FakeBookmarkRepository();
    final progressRepository = _FakeReadingProgressRepository();
    final container = _container(bookmarkRepository, progressRepository);

    await container.read(bookmarksProvider.future);
    final notifier = container.read(bookmarksProvider.notifier);

    await notifier.save(_bookmark(2, 255));
    await notifier.save(_bookmark(18, 10));

    final bookmarks = await container.read(bookmarksProvider.future);
    expect(bookmarks, hasLength(1));
    expect(bookmarks.single.id, '18_10');
    expect(bookmarkRepository.saved.map((bookmark) => bookmark.id), ['18_10']);
  });

  test('the active bookmark syncs its verse to reading progress', () async {
    final bookmarkRepository = _FakeBookmarkRepository();
    final progressRepository = _FakeReadingProgressRepository();
    final container = _container(bookmarkRepository, progressRepository);

    await container.read(bookmarksProvider.future);
    final notifier = container.read(bookmarksProvider.notifier);

    await notifier.save(_bookmark(2, 255));
    var progress = container.read(readingProgressProvider);
    expect(progress?.surahNumber, 2);
    expect(progress?.ayahNumber, 255);
    expect(progressRepository.saved, isNotEmpty);

    final savesBefore = progressRepository.saved.length;
    await notifier.save(_bookmark(18, 10));
    progress = container.read(readingProgressProvider);
    expect(progress?.surahNumber, 18);
    expect(progress?.ayahNumber, 10);
    expect(progressRepository.saved.length, greaterThan(savesBefore));
    expect(container.read(activeBookmarkProvider)?.id, '18_10');
  });

  test(
    'loading trims legacy multi-bookmark data to the newest entry',
    () async {
      final bookmarkRepository = _FakeBookmarkRepository()
        ..saved.addAll([_bookmark(18, 10), _bookmark(2, 255)]);
      final progressRepository = _FakeReadingProgressRepository();
      final container = _container(bookmarkRepository, progressRepository);

      final bookmarks = await container.read(bookmarksProvider.future);

      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.id, '18_10');
      expect(bookmarkRepository.saved.map((bookmark) => bookmark.id), [
        '18_10',
      ]);
    },
  );

  test('reading further keeps the bookmark as the saved marker', () async {
    final bookmarkRepository = _FakeBookmarkRepository();
    final progressRepository = _FakeReadingProgressRepository();
    final container = _container(bookmarkRepository, progressRepository);

    await container.read(bookmarksProvider.future);
    final notifier = container.read(bookmarksProvider.notifier);
    await notifier.save(_bookmark(2, 255));

    await container
        .read(readingProgressProvider.notifier)
        .record(surahNumber: 2, ayahNumber: 260, surahName: 'Surah 2');

    expect(container.read(readingProgressProvider)?.ayahNumber, 260);
    expect(container.read(activeBookmarkProvider)?.id, '2_255');
    expect(container.read(bookmarksProvider).value, hasLength(1));
  });
}
