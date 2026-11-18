/// Central place for external endpoints, storage keys and bundled assets.
abstract final class ApiEndpoints {
  static const String equranBase = 'https://equran.id/api/v2';
  static const String quranComBase = 'https://api.quran.com/api/v4';

  static const String surahList = '$equranBase/surat';

  static String surahDetail(int surahNumber) =>
      '$equranBase/surat/$surahNumber';

  /// Uthmani text of one chapter, used by the Madinah mushaf style.
  static String uthmaniVerses(int chapterNumber) =>
      '$quranComBase/verses/by_chapter/$chapterNumber'
      '?fields=text_uthmani&per_page=300&page=1';

  /// Hadith API dataset from renomureza/hadis-api-id.
  static const String hadithApiBase =
      'https://raw.githubusercontent.com/renomureza/hadis-api-id/main/src/data';
}

abstract final class HiveBoxes {
  static const String bookmarks = 'bookmarks';
  static const String quranCache = 'quran_cache';
  static const String settings = 'settings';
  static const String hadithCache = 'hadith_cache';
}

abstract final class AppAssets {
  static const String mushafPageIndex = 'assets/data/mushaf_page_index.json';
  static const String hadiths = 'assets/data/hadiths.json';
  static const String indonesiaRegions = 'assets/data/indonesia_regions.json';
  static const String indonesiaVillageDirectory = 'assets/data/wilayah';
}

abstract final class CacheTtl {
  static const Duration surahList = Duration(days: 7);
  static const Duration surahDetail = Duration(days: 30);
}
