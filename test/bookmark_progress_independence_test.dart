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
}
