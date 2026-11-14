import 'dart:convert';

import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../models/surah_models.dart';

/// Offline cache of Quran text. Entries are JSON blobs plus a timestamp so the
/// app can serve fresh data instantly and stale data when the network fails.
class QuranLocalDataSource {
  QuranLocalDataSource(this._box);

  final Box<dynamic> _box;

  static const String _surahListKey = 'surah_list';
  static String _surahDetailKey(int surahNumber) => 'surah_detail_$surahNumber';

  List<SurahModel>? readSurahList({bool allowStale = false}) {
    final raw = _read(
      _surahListKey,
      CacheTtl.surahList,
      allowStale: allowStale,
    );
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return [
        for (final item in decoded)
          if (item is Map) SurahModel.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> writeSurahList(List<SurahModel> surahs) {
    return _write(_surahListKey, [for (final surah in surahs) surah.toJson()]);
  }

  SurahDetailModel? readSurahDetail(
    int surahNumber, {
    bool allowStale = false,
  }) {
    final raw = _read(
      _surahDetailKey(surahNumber),
      CacheTtl.surahDetail,
      allowStale: allowStale,
    );
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return SurahDetailModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> writeSurahDetail(int surahNumber, SurahDetailModel detail) {
    return _write(_surahDetailKey(surahNumber), detail.toJson());
  }

  String? _read(String key, Duration ttl, {required bool allowStale}) {
    final value = _box.get(key);
    if (value is! Map) return null;

    final data = value['data'];
    if (data is! String) return null;
    if (allowStale) return data;

    final cachedAt = value['cachedAt'];
    if (cachedAt is! int) return null;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(cachedAt),
    );
    return age <= ttl ? data : null;
  }

  Future<void> _write(String key, Object payload) {
    return _box.put(key, <String, dynamic>{
      'data': jsonEncode(payload),
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
