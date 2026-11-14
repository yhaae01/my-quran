import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../datasources/reading_progress_local_data_source.dart';

class ReadingProgressRepositoryImpl implements ReadingProgressRepository {
  ReadingProgressRepositoryImpl(this._local);

  final ReadingProgressLocalDataSource _local;

  @override
  ReadingProgress? load() => _local.read();

  @override
  Future<void> save(ReadingProgress progress) => _local.write(progress);
}
