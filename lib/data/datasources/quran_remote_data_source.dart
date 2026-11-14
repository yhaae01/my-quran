import '../../core/constants/app_constants.dart';
import '../../core/error/failure.dart';
import '../../core/network/api_client.dart';
import '../models/surah_models.dart';

class QuranRemoteDataSource {
  QuranRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<SurahModel>> fetchSurahs() async {
    final json = await _client.getJson(ApiEndpoints.surahList);
    final data = json['data'];
    if (data is! List) {
      throw const Failure(
        'Daftar surah tidak ditemukan pada respons server.',
        kind: FailureKind.parse,
      );
    }
    try {
      return [
        for (final item in data)
          if (item is Map)
            SurahModel.fromEquran(Map<String, dynamic>.from(item)),
      ];
    } catch (error) {
      throw Failure(
        'Daftar surah tidak dapat dibaca.',
        kind: FailureKind.parse,
        cause: error,
      );
    }
  }

  Future<SurahDetailModel> fetchSurahDetail(int surahNumber) async {
    final json = await _client.getJson(ApiEndpoints.surahDetail(surahNumber));
    final data = json['data'];
    if (data is! Map) {
      throw const Failure(
        'Detail surah tidak ditemukan pada respons server.',
        kind: FailureKind.parse,
      );
    }
    try {
      final model = SurahDetailModel.fromEquran(
        Map<String, dynamic>.from(data),
      );
      if (model.ayahs.isEmpty) {
        throw const FormatException('Surah tidak memiliki ayat.');
      }
      return model;
    } on Failure {
      rethrow;
    } catch (error) {
      throw Failure(
        'Detail surah tidak dapat dibaca.',
        kind: FailureKind.parse,
        cause: error,
      );
    }
  }

  /// Returns Madinah/uthmani text keyed by verse number. Used as an optional
  /// enrichment so the reader still works when quran.com is unavailable.
  Future<Map<int, String>> fetchUthmaniVerses(int chapterNumber) async {
    final json = await _client.getJson(
      ApiEndpoints.uthmaniVerses(chapterNumber),
    );
    final verses = json['verses'];
    if (verses is! List) {
      throw const Failure(
        'Teks Uthmani tidak ditemukan pada respons server.',
        kind: FailureKind.parse,
      );
    }

    final result = <int, String>{};
    for (final item in verses) {
      if (item is! Map) continue;
      final key = item['verse_key'];
      final text = item['text_uthmani'];
      if (key is! String || text is! String) continue;
      final parts = key.split(':');
      if (parts.length != 2) continue;
      final verseNumber = int.tryParse(parts[1]);
      if (verseNumber == null) continue;
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) result[verseNumber] = trimmed;
    }
    if (result.isEmpty) {
      throw const Failure('Teks Uthmani kosong.', kind: FailureKind.parse);
    }
    return result;
  }
}
