import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bookmark.dart';
import 'core_providers.dart';

typedef BookmarkKey = ({int surah, int verse});

class BookmarksNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() {
    return ref.watch(getBookmarksProvider)();
  }

  /// Adds a bookmark or replaces the one already attached to the same verse.
  Future<void> save(Bookmark bookmark) async {
    final current = state.value ?? await _fetch();
    for (final existing in current) {
      final sameVerse =
          existing.surahNumber == bookmark.surahNumber &&
          existing.verseNumber == bookmark.verseNumber;
      if (sameVerse && existing.id != bookmark.id) {
        await ref.read(deleteBookmarkProvider)(existing.id);
      }
    }
    await ref.read(saveBookmarkProvider)(bookmark);
    await _reload();
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
