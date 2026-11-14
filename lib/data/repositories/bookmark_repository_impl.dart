import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../datasources/bookmark_local_data_source.dart';
import '../models/bookmark_model.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  BookmarkRepositoryImpl(this._local);

  final BookmarkLocalDataSource _local;

  @override
  Future<List<Bookmark>> getBookmarks() async {
    return _local.readAll().map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveBookmark(Bookmark bookmark) {
    return _local.put(BookmarkModel.fromEntity(bookmark));
  }

  @override
  Future<void> deleteBookmark(String id) => _local.delete(id);
}
