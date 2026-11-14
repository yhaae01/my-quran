import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/prayer.dart';

const List<String> _weekdays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> _months = [
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

/// `HH:mm` in the schedule's timezone, independent of the device timezone.
String formatPrayerClock(PrayerMoment moment, String timeZoneId) {
  final location = tz.getLocation(timeZoneId);
  final local = tz.TZDateTime.from(moment.instant, location);
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// `Jumat, 14 November 2026` for a civil date.
String formatPrayerDate(DateTime civilDate) {
  final weekday = _weekdays[civilDate.weekday - 1];
  final month = _months[civilDate.month - 1];
  return '$weekday, ${civilDate.day} $month ${civilDate.year}';
}

/// `02:14:09` / `14:09` for the countdown card.
String formatCountdown(Duration duration) {
  final total = duration.isNegative ? 0 : duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  if (hours > 0) {
    return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
  }
  return '${_two(minutes)}:${_two(seconds)}';
}

/// Human countdown used on the widget and in the small header line.
String describeCountdown(Duration duration) {
  if (duration.inMinutes < 1) return 'kurang dari 1 menit';
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return '$minutes menit';
  if (minutes == 0) return '$hours jam';
  return '$hours jam $minutes menit';
}

String _two(int value) => value.toString().padLeft(2, '0');
