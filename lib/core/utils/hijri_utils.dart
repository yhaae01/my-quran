import 'package:hijri_date/hijri.dart';

const List<String> _hijriMonths = [
  'Muharram',
  'Safar',
  'Rabiul Awal',
  'Rabiul Akhir',
  'Jumadil Awal',
  'Jumadil Akhir',
  'Rajab',
  "Sya'ban",
  'Ramadhan',
  'Syawal',
  "Dzulqa'dah",
  'Dzulhijjah',
];

/// A civil Hijri date in the Umm al-Qura calendar, formatted for Indonesian
/// readers.
class HijriDay {
  const HijriDay({required this.day, required this.month, required this.year});

  final int day;
  final int month;
  final int year;

  String get monthName => _hijriMonths[(month - 1).clamp(0, 11)];

  /// e.g. `15 Jumadil Awal 1448 H`.
  String get label => '$day $monthName $year H';

  /// e.g. `15 Jumadil Awal`.
  String get dayAndMonth => '$day $monthName';

  factory HijriDay.fromDate(DateTime date) {
    final converted = HijriDate.fromDate(date);
    return HijriDay(
      day: converted.hDay,
      month: converted.hMonth,
      year: converted.hYear,
    );
  }
}

/// Umm al-Qura Hijri conversion for today's card and the home-screen widget.
String formatHijriDate(DateTime date) => HijriDay.fromDate(date).label;
