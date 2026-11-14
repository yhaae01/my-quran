import 'ayah.dart';
import 'surah.dart';

/// Number of pages in both the Madinah and Indonesian standard mushafs.
const int mushafPageCount = 604;

/// The two page layouts supported by the reader.
enum MushafStyle {
  kemenag(
    id: 'kemenag',
    label: 'Mushaf Standar Indonesia',
    description: 'Kemenag • rasm usmani Indonesia',
    fontFamily: 'ScheherazadeNew',
  ),
  madinah(
    id: 'madinah',
    label: 'Mushaf Madinah',
    description: 'Madinah • rasm usmani Madinah',
    fontFamily: 'AmiriQuran',
  );

  const MushafStyle({
    required this.id,
    required this.label,
    required this.description,
    required this.fontFamily,
  });

  final String id;
  final String label;
  final String description;
  final String fontFamily;

  static MushafStyle fromId(String? id) {
    return MushafStyle.values.firstWhere(
      (style) => style.id == id,
      orElse: () => MushafStyle.kemenag,
    );
  }
}

class PageStart {
  const PageStart({required this.surah, required this.ayah, required this.juz});

  final int surah;
  final int ayah;
  final int juz;
}

/// Inclusive start and exclusive end of the verses printed on one page.
class MushafPageRange {
  const MushafPageRange({
    required this.startSurah,
    required this.startAyah,
    this.endSurah,
    this.endAyah,
  });

  final int startSurah;
  final int startAyah;
  final int? endSurah;
  final int? endAyah;

  bool contains(int surah, int ayah) {
    if (surah < startSurah) return false;
    if (surah == startSurah && ayah < startAyah) return false;

    final lastSurah = endSurah;
    if (lastSurah != null) {
      if (surah > lastSurah) return false;
      if (surah == lastSurah && ayah >= (endAyah ?? 1)) return false;
    }
    return true;
  }

  /// Last surah that actually has a verse inside this page.
  int get lastSurahNumber {
    final lastSurah = endSurah;
    if (lastSurah == null) return 114;
    if (endAyah == 1) return lastSurah - 1;
    return lastSurah;
  }
}

/// Asset-backed mapping between canonical verse order and mushaf pages.
///
/// Each style stores only the first verse of every page, which keeps the
/// bundled index tiny while still allowing exact page lookups in both
/// directions.
class MushafPageIndex {
  const MushafPageIndex({required this.style, required this.starts});

  final MushafStyle style;
  final List<PageStart> starts;

  int get pageCount => starts.length;

  PageStart startOf(int pageNumber) {
    final index = (pageNumber - 1).clamp(0, starts.length - 1);
    return starts[index];
  }

  /// 1-based page that contains the given verse.
  int pageOf(int surah, int ayah) {
    final key = surah * 1000 + ayah;
    var low = 0;
    var high = starts.length - 1;
    var result = 0;

    while (low <= high) {
      final middle = (low + high) ~/ 2;
      final start = starts[middle];
      if (start.surah * 1000 + start.ayah <= key) {
        result = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return result + 1;
  }

  MushafPageRange rangeOf(int pageNumber) {
    final start = startOf(pageNumber);
    final next = pageNumber < pageCount ? startOf(pageNumber + 1) : null;
    return MushafPageRange(
      startSurah: start.surah,
      startAyah: start.ayah,
      endSurah: next?.surah,
      endAyah: next?.ayah,
    );
  }

  factory MushafPageIndex.fromJson(
    Map<String, dynamic> json,
    MushafStyle style,
  ) {
    final styles = json['styles'];
    if (styles is! Map) {
      throw const FormatException('Indeks halaman tidak memiliki styles.');
    }
    final entry = styles[style.id];
    if (entry is! Map || entry['starts'] is! List) {
      throw FormatException('Indeks halaman ${style.id} tidak tersedia.');
    }

    final starts = <PageStart>[];
    for (final raw in entry['starts'] as List) {
      if (raw is! List || raw.length < 3) {
        throw const FormatException('Baris indeks halaman tidak valid.');
      }
      starts.add(
        PageStart(
          surah: (raw[0] as num).toInt(),
          ayah: (raw[1] as num).toInt(),
          juz: (raw[2] as num).toInt(),
        ),
      );
    }
    if (starts.isEmpty) {
      throw const FormatException('Indeks halaman kosong.');
    }
    return MushafPageIndex(style: style, starts: starts);
  }
}

class MushafPage {
  const MushafPage({
    required this.number,
    required this.juz,
    required this.style,
    required this.surahs,
    required this.ayahs,
  });

  final int number;
  final int juz;
  final MushafStyle style;
  final List<Surah> surahs;
  final List<Ayah> ayahs;
}
