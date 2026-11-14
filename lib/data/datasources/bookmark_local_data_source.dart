import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/bookmark_model.dart';

class BookmarkLocalDataSource {
  BookmarkLocalDataSource(this._box);

  final Box<BookmarkModel> _box;

  /// Reads every bookmark, skipping entries that cannot be decoded (for
  /// example data written by an older schema). One bad record must never take
  /// down the whole bookmark screen.
  List<BookmarkModel> readAll() {
    final bookmarks = <BookmarkModel>[];

    List<dynamic> keys;
    try {
      keys = _box.keys.toList();
    } catch (error) {
      debugPrint('Daftar penanda tidak dapat dibaca: $error');
      return const [];
    }

    for (final key in keys) {
      try {
        final bookmark = _box.get(key);
        if (bookmark != null) bookmarks.add(bookmark);
      } catch (error) {
        debugPrint('Melewati penanda yang rusak ($key): $error');
      }
    }

    bookmarks.sort((a, b) {
      final left = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return left.compareTo(right);
    });
    return bookmarks;
  }

  Future<void> put(BookmarkModel bookmark) {
    return _box.put(bookmark.id, bookmark);
  }

  Future<void> delete(String id) => _box.delete(id);
}
