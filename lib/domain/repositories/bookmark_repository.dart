import '../entities/bookmark.dart';

abstract interface class BookmarkRepository {
  Future<List<Bookmark>> getBookmarks();

  Future<void> saveBookmark(Bookmark bookmark);

  Future<void> deleteBookmark(String id);
}
