import 'package:hive/hive.dart';

import '../../domain/entities/daily_tilawah.dart';

/// Persists the current 1D1J target inside the settings box so it survives
/// restarts and works entirely offline.
class DailyTilawahLocalDataSource {
  DailyTilawahLocalDataSource(this._box);

  final Box<dynamic> _box;

  static const String _key = 'daily_tilawah';

  DailyTilawah? read() {
    final stored = _box.get(_key);
    if (stored is! Map) return null;
    return DailyTilawah.fromMap(stored);
  }

  Future<void> write(DailyTilawah daily) async {
    await _box.put(_key, daily.toMap());
  }
}
