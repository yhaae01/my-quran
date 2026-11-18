import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/core/utils/text_utils.dart';
import 'package:my_quran/domain/entities/daily_tilawah.dart';
import 'package:my_quran/domain/entities/member_progress.dart';
import 'package:my_quran/domain/entities/reading_progress.dart';

ReadingProgress _at(int surah, int ayah) {
  return ReadingProgress(
    surahNumber: surah,
    ayahNumber: ayah,
    surahName: 'Surah $surah',
    updatedAt: DateTime(2026, 11, 18, 8),
  );
}

void main() {
  group('DailyTilawah', () {
    test('starts at the current position with a one-juz target', () {
      final daily = DailyTilawah.startingAt(
        baselineVerse: 300,
        date: DateTime(2026, 11, 18, 15),
      );

      expect(daily.date, DateTime(2026, 11, 18));
      expect(daily.baselineVerse, 300);
      expect(daily.targetPages, 20);
      expect(daily.targetLabel, '20 halaman · 1 juz');
      expect(daily.dateKey, '2026-11-18');
      expect(daily.isForDay(DateTime(2026, 11, 18, 23, 59)), isTrue);
      expect(daily.isForDay(DateTime(2026, 11, 19)), isFalse);
    });

    test('turns verse progress into pages read today', () {
      // Al-Baqarah 1 is the 8th verse of the Qur'an; Al-Baqarah 11 is the 18th,
      // so a baseline at verse 8 means ten verses were read.
      final daily = DailyTilawah.startingAt(baselineVerse: 8);
      final progress = _at(2, 11);

      expect(progress.versesRead, 18);
      expect(daily.versesReadSince(progress), 10);
      expect(
        daily.pagesRead(progress),
        closeTo(10 / DailyTilawah.versesPerPage, 1e-9),
      );
      expect(daily.ratioFor(progress), lessThan(0.1));
      expect(daily.isCompleteFor(progress), isFalse);
    });

    test('clamps progress when the position moves backwards', () {
      final daily = DailyTilawah.startingAt(baselineVerse: 100);
      final progress = _at(1, 7); // verse 7, before the baseline

      expect(daily.versesReadSince(progress), 0);
      expect(daily.pagesRead(progress), 0);
      expect(daily.isCompleteFor(progress), isFalse);
    });

    test('manual pages count and are capped at the target', () {
      final daily = DailyTilawah.startingAt(
        baselineVerse: 0,
        date: DateTime(2026, 11, 18),
      );
      final progress = _at(1, 1); // one verse read

      final manual = daily.copyWith(manualPages: 5);
      expect(manual.pagesRead(progress), greaterThan(5));
      expect(
        manual.ratioFor(progress),
        closeTo(manual.pagesRead(progress) / 20, 1e-9),
      );
      expect(manual.isCompleteFor(progress), isFalse);

      final almostDone = daily.copyWith(manualPages: 20);
      expect(almostDone.pagesRead(progress), 20);
      expect(almostDone.ratioFor(progress), 1);
      expect(almostDone.isCompleteFor(progress), isTrue);
    });

    test('a full daily reading completes the target', () {
      final daily = DailyTilawah.startingAt(baselineVerse: 0);
      // Al-Baqarah 210 is the 217th verse, just over one juz.
      final progress = _at(2, 210);

      expect(progress.versesRead, 217);
      expect(daily.pagesRead(progress), 20);
      expect(daily.isCompleteFor(progress), isTrue);
      expect(daily.ratioFor(progress), 1);
      expect(daily.percentFor(progress), 100);
      expect(daily.remainingPages(progress), 0);
    });

    test('a manually completed target always reports 100 percent', () {
      final daily = DailyTilawah.startingAt(baselineVerse: 0)
          .copyWith(completed: true, completedAt: DateTime(2026, 11, 18, 20));
      final progress = _at(1, 1);

      expect(daily.percentFor(progress), 100);
      expect(daily.ratioFor(progress), 1);
      expect(daily.isCompleteFor(progress), isTrue);
      expect(daily.completedAt, DateTime(2026, 11, 18, 20));
    });

    test('round-trips through the Hive map form', () {
      final daily =
          DailyTilawah.startingAt(
            baselineVerse: 42,
            date: DateTime(2026, 11, 18),
          ).copyWith(
            manualPages: 3,
            completed: true,
            completedAt: DateTime(2026, 11, 18, 21),
          );

      final restored = DailyTilawah.fromMap(daily.toMap());

      expect(restored, daily);
      expect(restored!.dateKey, '2026-11-18');
      expect(restored.manualPages, 3);
      expect(restored.completed, isTrue);
    });

    test('ignores malformed stored maps', () {
      expect(DailyTilawah.fromMap(null), isNull);
      expect(DailyTilawah.fromMap({'date': 'bukan-tanggal'}), isNull);
      expect(DailyTilawah.fromMap({'baseline_verse': 5}), isNull);
    });
  });

  group('Challenge daily status', () {
    test('reports today and completion for group members', () {
      final member = MemberProgress(
        uid: 'u1',
        displayName: 'Aisyah',
        progress: _at(2, 11),
        dailyPages: 4.5,
        dailyTargetPages: 20,
        dailyCompleted: false,
        dailyDate: DailyTilawah.dateKeyFor(DateTime.now()),
      );

      expect(member.hasDailyTargetToday, isTrue);
      expect(member.dailyRatio, closeTo(4.5 / 20, 1e-9));
      expect(
        MemberProgress(
          uid: 'u2',
          displayName: 'Ali',
          progress: _at(1, 1),
        ).hasDailyTargetToday,
        isFalse,
      );
    });
  });

  group('formatPageCount', () {
    test('formats whole and fractional pages for Indonesian copy', () {
      expect(formatPageCount(7), '7');
      expect(formatPageCount(7.0), '7');
      expect(formatPageCount(7.25), '7,3');
      expect(formatPageCount(0.5), '0,5');
    });
  });
}
