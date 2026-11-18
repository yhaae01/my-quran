import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/core/constants/app_constants.dart';
import 'package:my_quran/domain/entities/mushaf.dart';
import 'package:my_quran/domain/repositories/mushaf_repository.dart';
import 'package:my_quran/presentation/providers/core_providers.dart';
import 'package:my_quran/presentation/providers/quran_providers.dart';

/// Uses the bundled page index without touching Hive or the network.
class _AssetMushafRepository implements MushafRepository {
  _AssetMushafRepository(this._index);

  final MushafPageIndex _index;

  @override
  Future<int> juzForVerse(
    MushafStyle style, {
    required int surah,
    required int ayah,
  }) async => _index.juzForVerse(surah, ayah);

  @override
  Future<int> pageForVerse(
    MushafStyle style, {
    required int surah,
    required int ayah,
  }) async => _index.pageOf(surah, ayah);

  @override
  Future<MushafPage> getPage(MushafStyle style, int pageNumber) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerFor(MushafStyle style) async {
    final raw = await rootBundle.loadString(AppAssets.mushafPageIndex);
    final index = MushafPageIndex.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
      style,
    );
    final container = ProviderContainer(
      overrides: [
        mushafRepositoryProvider.overrideWithValue(
          _AssetMushafRepository(index),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('builds a juz label for every surah', () async {
    final container = await containerFor(MushafStyle.madinah);
    final ranges = await container.read(
      surahJuzRangesProvider(MushafStyle.madinah).future,
    );

    expect(ranges, hasLength(114));
    expect(ranges[1], 'Juz 1');
    expect(ranges[2], 'Juz 1–3');
    expect(ranges[18], 'Juz 15–16');
    expect(ranges[67], 'Juz 29');
    expect(ranges[78], 'Juz 30');
    expect(ranges[114], 'Juz 30');
  });

  test('keeps the same canonical ranges for the Kemenag layout', () async {
    final container = await containerFor(MushafStyle.kemenag);
    final ranges = await container.read(
      surahJuzRangesProvider(MushafStyle.kemenag).future,
    );

    expect(ranges[2], 'Juz 1–3');
    expect(ranges[36], 'Juz 22–23');
    expect(ranges[114], 'Juz 30');
  });
}
