import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/core/constants/app_constants.dart';
import 'package:my_quran/domain/entities/mushaf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled index exposes 604 pages for both mushaf styles', () async {
    final raw = await rootBundle.loadString(AppAssets.mushafPageIndex);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    for (final style in MushafStyle.values) {
      final index = MushafPageIndex.fromJson(json, style);
      expect(index.pageCount, 604, reason: 'page count for ${style.id}');
      expect(index.startOf(1).surah, 1, reason: 'first page ${style.id}');
      expect(index.startOf(604).surah, 112, reason: 'last page ${style.id}');
      expect(index.pageOf(1, 1), 1);
      expect(index.pageOf(112, 1), 604);

      // Juz boundaries used by the Surah header.
      expect(index.juzForVerse(1, 1), 1);
      expect(index.juzForVerse(2, 141), 1);
      expect(index.juzForVerse(2, 142), 2);
      expect(index.juzForVerse(2, 286), 3);
      expect(index.juzForVerse(18, 1), 15);
      expect(index.juzForVerse(114, 6), 30);
    }
  });
}
