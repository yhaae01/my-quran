import 'package:hijri/hijri_calendar.dart';

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

const List<String> hijriWeekdaysShort = [
  'Ahd',
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
];

const List<String> hijriWeekdaysFull = [
  'Ahad',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  "Jum'at",
  'Sabtu',
];

const List<String> _gregorianMonthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// A civil Hijri date in the Umm al-Qura calendar, formatted for Indonesian readers.
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
    final converted = HijriCalendar.fromDate(date);
    return HijriDay(
      day: converted.hDay,
      month: converted.hMonth,
      year: converted.hYear,
    );
  }
}

/// A single cell in the Hijri calendar month grid.
class HijriCalendarCell {
  const HijriCalendarCell({
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
    required this.gregorianDate,
    required this.isCurrentMonth,
    required this.isToday,
    this.observance,
    this.isSunnahFasting = false,
  });

  final int hijriDay;
  final int hijriMonth;
  final int hijriYear;
  final DateTime gregorianDate;
  final bool isCurrentMonth;
  final bool isToday;
  final String? observance;
  final bool isSunnahFasting;

  String get monthName => _hijriMonths[(hijriMonth - 1).clamp(0, 11)];
  String get fullHijriLabel => '$hijriDay $monthName $hijriYear H';

  String get gregorianDayString => gregorianDate.day.toString();
  String get gregorianMonthName =>
      _gregorianMonthNames[gregorianDate.month - 1];

  String get gregorianFormatted =>
      '${gregorianDate.day} $gregorianMonthName ${gregorianDate.year}';

  String get weekdayName {
    final idx = gregorianDate.weekday % 7;
    return hijriWeekdaysFull[idx];
  }
}

/// Represents a full Hijri month grid with aligned weeks and adjacent padding days.
class HijriCalendarMonth {
  const HijriCalendarMonth({
    required this.year,
    required this.month,
    required this.daysInMonth,
    required this.cells,
    required this.gregorianStart,
    required this.gregorianEnd,
  });

  final int year;
  final int month;
  final int daysInMonth;
  final List<HijriCalendarCell> cells;
  final DateTime gregorianStart;
  final DateTime gregorianEnd;

  String get monthName => _hijriMonths[(month - 1).clamp(0, 11)];
  String get title => '$monthName $year H';

  String get gregorianRangeLabel {
    final startM = _gregorianMonthNames[gregorianStart.month - 1];
    final endM = _gregorianMonthNames[gregorianEnd.month - 1];
    if (gregorianStart.year == gregorianEnd.year) {
      if (gregorianStart.month == gregorianEnd.month) {
        return '$startM ${gregorianStart.year}';
      }
      return '$startM – $endM ${gregorianStart.year}';
    }
    return '$startM ${gregorianStart.year} – $endM ${gregorianEnd.year}';
  }

  HijriCalendarMonth nextMonth([DateTime? today]) {
    if (month == 12) {
      return HijriCalendarMonth.fromHijri(year + 1, 1, today: today);
    }
    return HijriCalendarMonth.fromHijri(year, month + 1, today: today);
  }

  HijriCalendarMonth previousMonth([DateTime? today]) {
    if (month == 1) {
      return HijriCalendarMonth.fromHijri(year - 1, 12, today: today);
    }
    return HijriCalendarMonth.fromHijri(year, month - 1, today: today);
  }

  factory HijriCalendarMonth.fromDate(DateTime date, {DateTime? today}) {
    final h = HijriCalendar.fromDate(date);
    return HijriCalendarMonth.fromHijri(h.hYear, h.hMonth, today: today);
  }

  factory HijriCalendarMonth.fromHijri(int year, int month, {DateTime? today}) {
    final effectiveToday = today ?? DateTime.now();
    final cal = HijriCalendar();

    final daysInCurrentMonth = cal.getDaysInMonth(year, month);
    final gFirst = cal.hijriToGregorian(year, month, 1);
    final gLast = cal.hijriToGregorian(year, month, daysInCurrentMonth);

    // Weekday in Dart: Mon=1, ..., Sat=6, Sun=7.
    // In our grid starting with Ahad (Sun=0):
    final leadingPaddingCount = gFirst.weekday % 7;

    final cells = <HijriCalendarCell>[];

    // 1. Leading padding cells from previous Hijri month
    if (leadingPaddingCount > 0) {
      final prevYear = month == 1 ? year - 1 : year;
      final prevMonth = month == 1 ? 12 : month - 1;
      final prevMonthDays = cal.getDaysInMonth(prevYear, prevMonth);

      final startDay = prevMonthDays - leadingPaddingCount + 1;
      for (var d = startDay; d <= prevMonthDays; d++) {
        final gDate = cal.hijriToGregorian(prevYear, prevMonth, d);
        final isToday = _isSameDay(gDate, effectiveToday);
        final observance = _getObservance(prevYear, prevMonth, d, gDate);
        final isFasting = _isSunnahFasting(prevYear, prevMonth, d, gDate);

        cells.add(
          HijriCalendarCell(
            hijriDay: d,
            hijriMonth: prevMonth,
            hijriYear: prevYear,
            gregorianDate: gDate,
            isCurrentMonth: false,
            isToday: isToday,
            observance: observance,
            isSunnahFasting: isFasting,
          ),
        );
      }
    }

    // 2. Days of the current Hijri month
    for (var d = 1; d <= daysInCurrentMonth; d++) {
      final gDate = cal.hijriToGregorian(year, month, d);
      final isToday = _isSameDay(gDate, effectiveToday);
      final observance = _getObservance(year, month, d, gDate);
      final isFasting = _isSunnahFasting(year, month, d, gDate);

      cells.add(
        HijriCalendarCell(
          hijriDay: d,
          hijriMonth: month,
          hijriYear: year,
          gregorianDate: gDate,
          isCurrentMonth: true,
          isToday: isToday,
          observance: observance,
          isSunnahFasting: isFasting,
        ),
      );
    }

    // 3. Trailing padding cells for the next Hijri month (complete 7 columns)
    final trailingPaddingCount = (7 - (cells.length % 7)) % 7;
    if (trailingPaddingCount > 0) {
      final nextYear = month == 12 ? year + 1 : year;
      final nextMonth = month == 12 ? 1 : month + 1;

      for (var d = 1; d <= trailingPaddingCount; d++) {
        final gDate = cal.hijriToGregorian(nextYear, nextMonth, d);
        final isToday = _isSameDay(gDate, effectiveToday);
        final observance = _getObservance(nextYear, nextMonth, d, gDate);
        final isFasting = _isSunnahFasting(nextYear, nextMonth, d, gDate);

        cells.add(
          HijriCalendarCell(
            hijriDay: d,
            hijriMonth: nextMonth,
            hijriYear: nextYear,
            gregorianDate: gDate,
            isCurrentMonth: false,
            isToday: isToday,
            observance: observance,
            isSunnahFasting: isFasting,
          ),
        );
      }
    }

    return HijriCalendarMonth(
      year: year,
      month: month,
      daysInMonth: daysInCurrentMonth,
      cells: cells,
      gregorianStart: gFirst,
      gregorianEnd: gLast,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String? _getObservance(
    int hYear,
    int hMonth,
    int hDay,
    DateTime gDate,
  ) {
    if (hMonth == 1 && hDay == 1) return 'Tahun Baru Islam';
    if (hMonth == 1 && hDay == 9) return "Puasa Tasu'a";
    if (hMonth == 1 && hDay == 10) return 'Puasa Asyura';
    if (hMonth == 3 && hDay == 12) return 'Maulid Nabi Muhammad SAW';
    if (hMonth == 7 && hDay == 27) return "Isra' Mi'raj";
    if (hMonth == 8 && hDay == 15) return "Malam Nisfu Sya'ban";
    if (hMonth == 9 && hDay == 1) return 'Awal Ramadhan';
    if (hMonth == 9 && hDay == 17) return "Nuzulul Qur'an";
    if (hMonth == 9 &&
        (hDay == 21 || hDay == 23 || hDay == 25 || hDay == 27 || hDay == 29)) {
      return 'Malam Lailatul Qadar';
    }
    if (hMonth == 10 && hDay == 1) return 'Hari Raya Idul Fitri';
    if (hMonth == 10 && hDay == 2) return 'Idul Fitri Hari ke-2';
    if (hMonth == 12 && hDay == 8) return 'Hari Tarwiyah';
    if (hMonth == 12 && hDay == 9) return 'Hari / Puasa Arafah';
    if (hMonth == 12 && hDay == 10) return 'Hari Raya Idul Adha';
    if (hMonth == 12 && (hDay == 11 || hDay == 12 || hDay == 13)) {
      return 'Hari Tasyrik (Haram Puasa)';
    }

    // Ayyamul Bidh (13, 14, 15) except in Ramadan or 13 Dzulhijjah
    if ((hDay == 13 || hDay == 14 || hDay == 15) &&
        hMonth != 9 &&
        !(hMonth == 12 && hDay == 13)) {
      return 'Puasa Ayyamul Bidh';
    }

    // Regular Monday / Thursday sunnah fasting
    if (gDate.weekday == DateTime.monday &&
        hMonth != 9 &&
        !(hMonth == 10 && hDay == 1) &&
        !(hMonth == 12 && (hDay >= 10 && hDay <= 13))) {
      return 'Puasa Sunnah Senin';
    }
    if (gDate.weekday == DateTime.thursday &&
        hMonth != 9 &&
        !(hMonth == 10 && hDay == 1) &&
        !(hMonth == 12 && (hDay >= 10 && hDay <= 13))) {
      return 'Puasa Sunnah Kamis';
    }

    return null;
  }

  static bool _isSunnahFasting(
    int hYear,
    int hMonth,
    int hDay,
    DateTime gDate,
  ) {
    // Prohibited days (Idul Fitri, Idul Adha, Hari Tasyrik)
    if (hMonth == 10 && hDay == 1) return false;
    if (hMonth == 12 && (hDay >= 10 && hDay <= 13)) return false;

    // Obligatory fasting month
    if (hMonth == 9) return false;

    // Specific sunnah fasting days
    if (hMonth == 1 && (hDay == 9 || hDay == 10)) return true;
    if (hMonth == 12 && hDay == 9) return true;
    if (hDay == 13 || hDay == 14 || hDay == 15) return true;
    if (gDate.weekday == DateTime.monday ||
        gDate.weekday == DateTime.thursday) {
      return true;
    }
    return false;
  }
}

/// Umm al-Qura Hijri conversion for today's card and the home-screen widget.
String formatHijriDate(DateTime date) => HijriDay.fromDate(date).label;
