import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/core/utils/hijri_utils.dart';

void main() {
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
}
