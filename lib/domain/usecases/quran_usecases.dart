import '../entities/mushaf.dart';
import '../entities/surah.dart';
import '../repositories/mushaf_repository.dart';
import '../repositories/quran_repository.dart';

class GetSurahs {
  const GetSurahs(this._repository);

  final QuranRepository _repository;

  Future<List<Surah>> call({bool forceRefresh = false}) {
    return _repository.getSurahs(forceRefresh: forceRefresh);
  }
}

class GetSurahDetail {
  const GetSurahDetail(this._repository);

  final QuranRepository _repository;

  Future<SurahDetail> call(int surahNumber, {bool forceRefresh = false}) {
    return _repository.getSurahDetail(surahNumber, forceRefresh: forceRefresh);
  }
}

class GetMushafPage {
  const GetMushafPage(this._repository);

  final MushafRepository _repository;

  Future<MushafPage> call(MushafStyle style, int pageNumber) {
    return _repository.getPage(style, pageNumber);
  }
}

class LocateMushafPage {
  const LocateMushafPage(this._repository);

  final MushafRepository _repository;

  Future<int> call(MushafStyle style, {required int surah, required int ayah}) {
    return _repository.pageForVerse(style, surah: surah, ayah: ayah);
  }
}
