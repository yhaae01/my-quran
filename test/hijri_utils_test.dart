import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/core/utils/hijri_utils.dart';

void main() {
  group('HijriDay basics', () {
    test('converts a known Gregorian date to the Umm al-Qura calendar', () {
      final hijri = HijriDay.fromDate(DateTime(2024, 3, 11));
      expect(hijri.day, 1);
      expect(hijri.month, 9);
      expect(hijri.year, 1445);
      expect(hijri.label, '1 Ramadhan 1445 H');
    });

    test('advances one Hijri day when the Gregorian date advances one day', () {
      final first = HijriDay.fromDate(DateTime(2026, 11, 15));
      final second = HijriDay.fromDate(DateTime(2026, 11, 16));
      expect(second.day, first.day + 1);
    });

    test('formatHijriDate appends the H suffix', () {
      expect(formatHijriDate(DateTime(2026, 11, 15)), endsWith(' H'));
    });
  });

  group('HijriCalendarMonth & HijriCalendarCell', () {
    final fixedToday = DateTime(2026, 11, 15);

    test('generates full month with aligned weeks in multiples of 7', () {
      final month = HijriCalendarMonth.fromDate(fixedToday, today: fixedToday);

      expect(month.monthName, 'Jumadil Akhir');
      expect(month.year, 1448);
      expect(month.daysInMonth, inInclusiveRange(29, 30));

      // Cells count must be a multiple of 7
      expect(month.cells.length % 7, 0);

      // Verify that all days 1..daysInMonth are marked as current month
      final currentMonthCells = month.cells
          .where((c) => c.isCurrentMonth)
          .toList();
      expect(currentMonthCells.length, month.daysInMonth);
      for (var i = 0; i < currentMonthCells.length; i++) {
        expect(currentMonthCells[i].hijriDay, i + 1);
      }
    });

    test('highlights today cell correctly', () {
      final month = HijriCalendarMonth.fromDate(fixedToday, today: fixedToday);
      final todayCells = month.cells.where((c) => c.isToday).toList();

      expect(todayCells.length, 1);
      expect(todayCells.first.gregorianDate.year, 2026);
      expect(todayCells.first.gregorianDate.month, 11);
      expect(todayCells.first.gregorianDate.day, 15);
      expect(todayCells.first.isCurrentMonth, isTrue);
    });

    test('navigates next and previous month with year rollover', () {
      // 12 Dzulhijjah 1448 -> 1 Muharram 1449
      final dzulhijjah = HijriCalendarMonth.fromHijri(1448, 12);
      final nextYearMuharram = dzulhijjah.nextMonth();
      expect(nextYearMuharram.year, 1449);
      expect(nextYearMuharram.month, 1);
      expect(nextYearMuharram.monthName, 'Muharram');

      // 1 Muharram 1449 -> 12 Dzulhijjah 1448
      final prevYearDzulhijjah = nextYearMuharram.previousMonth();
      expect(prevYearDzulhijjah.year, 1448);
      expect(prevYearDzulhijjah.month, 12);
      expect(prevYearDzulhijjah.monthName, 'Dzulhijjah');
    });

    test('identifies Islamic observances and sunnah fasting', () {
      // 1 Muharram -> Tahun Baru Islam
      final muharram = HijriCalendarMonth.fromHijri(1448, 1);
      final day1 = muharram.cells.firstWhere(
        (c) => c.isCurrentMonth && c.hijriDay == 1,
      );
      expect(day1.observance, 'Tahun Baru Islam');

      // 10 Muharram -> Puasa Asyura
      final day10 = muharram.cells.firstWhere(
        (c) => c.isCurrentMonth && c.hijriDay == 10,
      );
      expect(day10.observance, 'Puasa Asyura');
      expect(day10.isSunnahFasting, isTrue);

      // Ayyamul Bidh on day 13 of a non-forbidden month
      final safar = HijriCalendarMonth.fromHijri(1448, 2);
      final day13 = safar.cells.firstWhere(
        (c) => c.isCurrentMonth && c.hijriDay == 13,
      );
      expect(day13.observance, 'Puasa Ayyamul Bidh');
      expect(day13.isSunnahFasting, isTrue);
    });
  });
}
