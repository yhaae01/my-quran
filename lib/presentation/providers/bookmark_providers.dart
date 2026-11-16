import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bookmark.dart';
import 'core_providers.dart';
import 'reading_progress_providers.dart';

typedef BookmarkKey = ({int surah, int verse});

class BookmarksNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() {
    return ref.watch(getBookmarksProvider)();
  }

  /// Adds a bookmark or replaces the one already attached to the same verse.
  ///
  /// Saving never touches reading progress: personal bookmarks are independent
  /// references. Only [setContinueReading] may move the shared reading position.
  Future<void> save(Bookmark bookmark) async {
    final current = state.value ?? await _fetch();
    final replaced = current.where(
      (existing) =>
          existing.id == bookmark.id ||
          (existing.surahNumber == bookmark.surahNumber &&
              existing.verseNumber == bookmark.verseNumber),
    );
    // Re-tagging the primary verse must not silently drop its resume flag.
    final keepContinueReading = replaced.any(
      (existing) => existing.isContinueReading,
    );
    final incoming = keepContinueReading && !bookmark.isContinueReading
        ? bookmark.copyWith(isContinueReading: true)
        : bookmark;

    for (final existing in replaced) {
      if (existing.id != incoming.id) {
        await ref.read(deleteBookmarkProvider)(existing.id);
      }
    }
    await ref.read(saveBookmarkProvider)(incoming);
    await _reload();
  }

  Future<void> remove(String id) async {
    await ref.read(deleteBookmarkProvider)(id);
    await _reload();
  }

  /// Marks [bookmark] as the one "Lanjutkan Bacaan" reference.
  ///
  /// Any previously primary bookmark is demoted in the same write, so exactly
  /// one personal bookmark can drive the resume card and the group challenge.
  /// The reading position is moved to this verse (also when it is behind the
  /// current position) because the reader explicitly picked it.
  Future<void> setContinueReading(Bookmark bookmark) async {
    final current = state.value ?? await _fetch();
    final updated = <Bookmark>[
      for (final item in current)
        if (item.id == bookmark.id)
          item.copyWith(isContinueReading: true)
        else if (item.isContinueReading)
          item.copyWith(isContinueReading: false)
        else
          item,
    ];
    await _persistChanged(current, updated);
    state = AsyncValue.data(updated);

    await ref
        .read(readingProgressProvider.notifier)
        .setPosition(
          surahNumber: bookmark.surahNumber,
          ayahNumber: bookmark.verseNumber,
          surahName: bookmark.displaySurahName,
        );
  }

  /// Drops the primary flag, for example after the reader moved past it.
  Future<void> clearContinueReading() async {
    final current = state.value ?? const <Bookmark>[];
    final primary = current.where((item) => item.isContinueReading).toList();
    if (primary.isEmpty) return;

    final updated = <Bookmark>[
      for (final item in current)
        item.isContinueReading ? item.copyWith(isContinueReading: false) : item,
    ];
    await _persistChanged(current, updated);
    state = AsyncValue.data(updated);
  }

  Future<List<Bookmark>> _fetch() => ref.read(getBookmarksProvider)();

  Future<void> _persistChanged(
    List<Bookmark> before,
    List<Bookmark> after,
  ) async {
    final previous = {for (final item in before) item.id: item};
    for (final item in after) {
      final old = previous[item.id];
      if (old == null || old.isContinueReading != item.isContinueReading) {
        await ref.read(saveBookmarkProvider)(item);
      }
    }
  }

  Future<void> _reload() async {
    state = AsyncValue.data(await _fetch());
  }
}

final AsyncNotifierProvider<BookmarksNotifier, List<Bookmark>>
bookmarksProvider = AsyncNotifierProvider<BookmarksNotifier, List<Bookmark>>(
  BookmarksNotifier.new,
);

final bookmarkAtProvider = Provider.family<Bookmark?, BookmarkKey>((ref, key) {
  final bookmarks = ref.watch(bookmarksProvider).value ?? const <Bookmark>[];
  for (final bookmark in bookmarks) {
    if (bookmark.surahNumber == key.surah &&
        bookmark.verseNumber == key.verse) {
      return bookmark;
    }
  }
  return null;
});

/// The single primary bookmark that backs "Lanjutkan Bacaan", if any.
final continueReadingBookmarkProvider = Provider<Bookmark?>((ref) {
  final bookmarks = ref.watch(bookmarksProvider).value ?? const <Bookmark>[];
  for (final bookmark in bookmarks) {
    if (bookmark.isContinueReading && bookmark.isNavigable) return bookmark;
  }
  return null;
});
