import '../entities/reading_progress.dart';
import '../repositories/reading_progress_repository.dart';

class LoadReadingProgress {
  const LoadReadingProgress(this._repository);

  final ReadingProgressRepository _repository;

  ReadingProgress? call() => _repository.load();
}

class SaveReadingProgress {
  const SaveReadingProgress(this._repository);

  final ReadingProgressRepository _repository;

  Future<void> call(ReadingProgress progress) => _repository.save(progress);
}
