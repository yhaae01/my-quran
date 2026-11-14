import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/mushaf.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/mushaf_repository.dart';
import '../../domain/repositories/quran_repository.dart';

class MushafRepositoryImpl implements MushafRepository {
  MushafRepositoryImpl({required this.quranRepository, required this.assets});

  final QuranRepository quranRepository;
  final AssetBundle assets;
  final Map<MushafStyle, MushafPageIndex> _indices = {};

  @override
  Future<MushafPage> getPage(MushafStyle style, int pageNumber) async {
    final index = await _indexFor(style);
    if (pageNumber < 1 || pageNumber > index.pageCount) {
      throw Failure(
        'Halaman $pageNumber tidak tersedia.',
        kind: FailureKind.notFound,
      );
    }

    final range = index.rangeOf(pageNumber);
    final lastSurah = range.lastSurahNumber;
    if (lastSurah < range.startSurah) {
      return MushafPage(
        number: pageNumber,
        juz: index.startOf(pageNumber).juz,
        style: style,
        surahs: const [],
        ayahs: const [],
      );
    }

    final details = await Future.wait([
      for (var surah = range.startSurah; surah <= lastSurah; surah++)
        quranRepository.getSurahDetail(surah),
    ]);

    final surahs = <Surah>[];
    final ayahs = <Ayah>[];
    for (final detail in details) {
      final selected = detail.ayahs
          .where((ayah) => range.contains(ayah.surahNumber, ayah.number))
          .toList();
      if (selected.isEmpty) continue;
      surahs.add(detail.surah);
      ayahs.addAll(selected);
    }

    return MushafPage(
      number: pageNumber,
      juz: index.startOf(pageNumber).juz,
      style: style,
      surahs: surahs,
      ayahs: ayahs,
    );
  }

  @override
  Future<int> pageForVerse(
    MushafStyle style, {
    required int surah,
    required int ayah,
  }) async {
    final index = await _indexFor(style);
    return index.pageOf(surah, ayah);
  }

  Future<MushafPageIndex> _indexFor(MushafStyle style) async {
    final cached = _indices[style];
    if (cached != null) return cached;

    try {
      final raw = await assets.loadString(AppAssets.mushafPageIndex);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Indeks halaman bukan objek JSON.');
      }
      final index = MushafPageIndex.fromJson(
        Map<String, dynamic>.from(decoded),
        style,
      );
      _indices[style] = index;
      return index;
    } catch (error) {
      throw Failure(
        'Indeks halaman mushaf tidak dapat dimuat.',
        kind: FailureKind.parse,
        cause: error,
      );
    }
  }
}
