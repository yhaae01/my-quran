import 'package:hive/hive.dart';

import '../models/bookmark_model.dart';

class BookmarkLocalDataSource {
  BookmarkLocalDataSource(this._box);

  final Box<BookmarkModel> _box;

  List<BookmarkModel> readAll() {
    final bookmarks = _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return bookmarks;
  }

  Future<void> put(BookmarkModel bookmark) {
    return _box.put(bookmark.id, bookmark);
  }

  Future<void> delete(String id) => _box.delete(id);
}
