import '../entities/reading_progress.dart';

abstract interface class ReadingProgressRepository {
  ReadingProgress? load();

  Future<void> save(ReadingProgress progress);
}
