import '../entities/bookmark.dart';
import '../repositories/bookmark_repository.dart';

class GetBookmarks {
  const GetBookmarks(this._repository);

  final BookmarkRepository _repository;

  Future<List<Bookmark>> call() => _repository.getBookmarks();
}

class SaveBookmark {
  const SaveBookmark(this._repository);

  final BookmarkRepository _repository;

  Future<void> call(Bookmark bookmark) => _repository.saveBookmark(bookmark);
}

class DeleteBookmark {
  const DeleteBookmark(this._repository);

  final BookmarkRepository _repository;

  Future<void> call(String id) => _repository.deleteBookmark(id);
}
