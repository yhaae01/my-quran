import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/core/utils/invite_code.dart';
import 'package:my_quran/domain/entities/reading_progress.dart';

void main() {
  group('Quran verse indexing', () {
    test('verse counts cover 114 surahs and 6236 verses', () {
      expect(surahVerseCounts.length, 114);
      expect(surahVerseCounts.fold<int>(0, (sum, count) => sum + count), 6236);
    });

    test('counts verses cumulatively across surahs', () {
      expect(cumulativeVerseNumber(1, 1), 1);
      expect(cumulativeVerseNumber(1, 7), 7);
      expect(cumulativeVerseNumber(2, 1), 8);
      expect(cumulativeVerseNumber(18, 1), 2141);
      expect(cumulativeVerseNumber(114, 6), totalQuranVerses);
    });

    test('clamps out-of-range positions to a valid verse', () {
      expect(cumulativeVerseNumber(0, 0), 1);
      expect(cumulativeVerseNumber(1, 99), 7);
      expect(cumulativeVerseNumber(500, 1), 6231);
    });
  });

  group('ReadingProgress', () {
    test('computes ratio and percent from the last verse reached', () {
      final progress = ReadingProgress(
        surahNumber: 2,
        ayahNumber: 286,
        surahName: 'Al-Baqarah',
        updatedAt: DateTime(2026, 11, 14),
      );

      expect(progress.versesRead, 293);
      expect(progress.ratio, closeTo(293 / 6236, 1e-9));
      expect(progress.percent, 5);
      expect(progress.isComplete, isFalse);
      expect(progress.reference, 'Al-Baqarah • Ayat 286');
    });

    test('finishing An-Nas reaches 100 percent', () {
      final progress = ReadingProgress(
        surahNumber: 114,
        ayahNumber: 6,
        surahName: 'An-Nas',
        updatedAt: DateTime(2026, 11, 14),
      );

      expect(progress.percent, 100);
      expect(progress.isComplete, isTrue);
    });

    test('round-trips through the Hive map form', () {
      final progress = ReadingProgress(
        surahNumber: 18,
        ayahNumber: 10,
        surahName: 'Al-Kahf',
        updatedAt: DateTime(2026, 11, 14, 9, 30),
      );

      final restored = ReadingProgress.fromMap(progress.toMap());

      expect(restored, isNotNull);
      expect(restored!.surahNumber, 18);
      expect(restored.ayahNumber, 10);
      expect(restored.surahName, 'Al-Kahf');
      expect(restored.updatedAt, DateTime(2026, 11, 14, 9, 30));
    });

    test('ignores malformed stored maps', () {
      expect(ReadingProgress.fromMap(null), isNull);
      expect(ReadingProgress.fromMap({'surah_number': 'x'}), isNull);
    });
  });

  group('InviteCode', () {
    test('generates six characters from the friendly alphabet', () {
      final random = Random(42);
      for (var index = 0; index < 200; index++) {
        final code = InviteCode.generate(random: random);
        expect(code.length, InviteCode.length);
        expect(InviteCode.isValid(code), isTrue);
        expect(code.contains(RegExp('[IO01]')), isFalse);
      }
    });

    test('normalizes typed codes', () {
      expect(InviteCode.normalize(' ab-c 23 '), 'ABC23');
      expect(InviteCode.normalize('ab12cd'), 'AB12CD');
    });

    test('rejects codes with ambiguous or missing characters', () {
      expect(InviteCode.isValid('AB1O23'), isFalse);
      expect(InviteCode.isValid('ABC23'), isFalse);
      expect(InviteCode.isValid('ABCDE2'), isTrue);
    });
  });
}
