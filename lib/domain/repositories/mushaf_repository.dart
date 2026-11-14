import '../entities/mushaf.dart';

abstract interface class MushafRepository {
  Future<MushafPage> getPage(MushafStyle style, int pageNumber);

  Future<int> pageForVerse(
    MushafStyle style, {
    required int surah,
    required int ayah,
  });
}
