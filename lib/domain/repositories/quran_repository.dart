import '../entities/surah.dart';

abstract interface class QuranRepository {
  Future<List<Surah>> getSurahs({bool forceRefresh = false});

  Future<SurahDetail> getSurahDetail(
    int surahNumber, {
    bool forceRefresh = false,
  });
}
