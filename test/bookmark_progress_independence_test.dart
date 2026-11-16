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
    color: BookmarkColor.blue,
    timestamp: DateTime(2026, 11, 15),
  );
}

void main() {
  test('saving personal bookmarks never changes challenge progress', () async {
    final bookmarkRepository = _FakeBookmarkRepository();
    final progressRepository = _FakeReadingProgressRepository();
    final container = ProviderContainer(
      overrides: [
        bookmarkRepositoryProvider.overrideWithValue(bookmarkRepository),
        readingProgressRepositoryProvider.overrideWithValue(progressRepository),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(bookmarksProvider.future), isEmpty);

    await container.read(bookmarksProvider.notifier).save(_bookmark(2, 255));
    await container.read(bookmarksProvider.notifier).save(_bookmark(18, 10));

    expect(bookmarkRepository.saved, hasLength(2));
    expect(progressRepository.saved, isEmpty);
    expect(container.read(readingProgressProvider), isNull);
  });

  test('only one bookmark can be the Lanjutkan Bacaan reference', () async {
    final bookmarkRepository = _FakeBookmarkRepository();
    final progressRepository = _FakeReadingProgressRepository();
    final container = ProviderContainer(
      overrides: [
        bookmarkRepositoryProvider.overrideWithValue(bookmarkRepository),
        readingProgressRepositoryProvider.overrideWithValue(progressRepository),
      ],
    );
    addTearDown(container.dispose);

    final first = _bookmark(2, 255);
    final second = _bookmark(18, 10);
    final notifier = container.read(bookmarksProvider.notifier);
    await container.read(bookmarksProvider.future);
    await notifier.save(first);
    await notifier.save(second);

    await notifier.setContinueReading(first);
    var primary = container.read(continueReadingBookmarkProvider);
    expect(primary?.id, first.id);
    // The designated position is the one mirrored to the challenge.
    expect(container.read(readingProgressProvider)?.surahNumber, 2);
    expect(progressRepository.saved, isNotEmpty);

    await notifier.setContinueReading(second);
    primary = container.read(continueReadingBookmarkProvider);
    expect(primary?.id, second.id);
    expect(container.read(readingProgressProvider)?.surahNumber, 18);

    final bookmarks = container.read(bookmarksProvider).value!;
    expect(bookmarks.where((bookmark) => bookmark.isContinueReading), [
      isA<Bookmark>().having((bookmark) => bookmark.id, 'id', second.id),
    ]);
  });

  test('secondary bookmarks never move progress or the primary flag', () async {
    final bookmarkRepository = _FakeBookmarkRepository();
    final progressRepository = _FakeReadingProgressRepository();
    final container = ProviderContainer(
      overrides: [
        bookmarkRepositoryProvider.overrideWithValue(bookmarkRepository),
        readingProgressRepositoryProvider.overrideWithValue(progressRepository),
      ],
    );
    addTearDown(container.dispose);

    final primaryBookmark = _bookmark(2, 255);
    final notifier = container.read(bookmarksProvider.notifier);
    await container.read(bookmarksProvider.future);
    await notifier.save(primaryBookmark);
    await notifier.setContinueReading(primaryBookmark);

    final progressAfterPin = container.read(readingProgressProvider);
    final savesAfterPin = progressRepository.saved.length;

    await notifier.save(_bookmark(3, 7));
    await notifier.save(_bookmark(4, 1));

    expect(container.read(readingProgressProvider), same(progressAfterPin));
    expect(progressRepository.saved, hasLength(savesAfterPin));
    expect(container.read(continueReadingBookmarkProvider)?.id, '2_255');
  });

  test('reading past the primary bookmark releases it', () async {
    final bookmarkRepository = _FakeBookmarkRepository();
    final progressRepository = _FakeReadingProgressRepository();
    final container = ProviderContainer(
      overrides: [
        bookmarkRepositoryProvider.overrideWithValue(bookmarkRepository),
        readingProgressRepositoryProvider.overrideWithValue(progressRepository),
      ],
    );
    addTearDown(container.dispose);

    final primaryBookmark = _bookmark(2, 255);
    final notifier = container.read(bookmarksProvider.notifier);
    await container.read(bookmarksProvider.future);
    await notifier.save(primaryBookmark);
    await notifier.setContinueReading(primaryBookmark);

    await container
        .read(readingProgressProvider.notifier)
        .record(surahNumber: 2, ayahNumber: 260, surahName: 'Surah 2');

    expect(container.read(continueReadingBookmarkProvider), isNull);
    expect(container.read(readingProgressProvider)?.ayahNumber, 260);
  });
}
