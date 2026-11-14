import 'package:hive/hive.dart';

import '../../domain/entities/reading_progress.dart';

/// Stores the last reading position on the device so it survives restarts and
/// keeps working without a network connection.
class ReadingProgressLocalDataSource {
  ReadingProgressLocalDataSource(this._box);

  final Box<dynamic> _box;

  static const String _key = 'reading_progress';

  ReadingProgress? read() {
    final stored = _box.get(_key);
    if (stored is! Map) return null;
    return ReadingProgress.fromMap(stored);
  }

  Future<void> write(ReadingProgress progress) async {
    await _box.put(_key, progress.toMap());
  }
}
