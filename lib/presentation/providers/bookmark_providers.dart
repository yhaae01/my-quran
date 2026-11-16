import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bookmark.dart';
import 'core_providers.dart';
import 'reading_progress_providers.dart';

typedef BookmarkKey = ({int surah, int verse});

/// Holds the single active bookmark of the app.
///
/// A bookmark is both the saved verse and the "Lanjutkan Bacaan" position:
/// saving a new one replaces the previous entry and pushes that verse to the
/// reading progress, which is mirrored to every group challenge the reader has
/// joined. Entries left over from older multi-bookmark builds are trimmed to
/// the newest one on load.
class BookmarksNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() async {
    final bookmarks = await ref.watch(getBookmarksProvider)();

    if (bookmarks.length <= 1) return bookmarks;

    // Older builds allowed many personal bookmarks. Keep only the newest one
    // so the single active bookmark rule also holds for upgraded installs.
    final active = bookmarks.first;
    for (final extra in bookmarks.skip(1)) {
      await ref.read(deleteBookmarkProvider)(extra.id);
    }
    return [active];
  }

  /// Saves [bookmark] as the one active bookmark, replacing the previous one.
  ///
  /// The saved verse immediately becomes the shared reading position, so the
  /// dashboard resume card and the group challenge follow the new marker.
  Future<void> save(Bookmark bookmark) async {
    final current = state.value ?? await _fetch();

    for (final existing in current) {
      if (existing.id != bookmark.id) {
        await ref.read(deleteBookmarkProvider)(existing.id);
      }
    }
    await ref.read(saveBookmarkProvider)(bookmark);
    state = AsyncValue.data([bookmark]);

    await ref
        .read(readingProgressProvider.notifier)
        .setPosition(
          surahNumber: bookmark.surahNumber,
          ayahNumber: bookmark.verseNumber,
          surahName: bookmark.displaySurahName,
        );
  }

  Future<void> remove(String id) async {
    await ref.read(deleteBookmarkProvider)(id);
    await _reload();
  }

  Future<List<Bookmark>> _fetch() => ref.read(getBookmarksProvider)();

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

/// The single active bookmark, which also backs "Lanjutkan Bacaan".
final activeBookmarkProvider = Provider<Bookmark?>((ref) {
  final bookmarks = ref.watch(bookmarksProvider).value ?? const <Bookmark>[];
  for (final bookmark in bookmarks) {
    if (bookmark.isNavigable) return bookmark;
  }
  return null;
});
