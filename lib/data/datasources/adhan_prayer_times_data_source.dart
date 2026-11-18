import 'package:adhan/adhan.dart' as adhan;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/prayer.dart';

/// Calculates a week of prayer times with the Indonesian (Kemenag) method.
///
/// Kemenag uses a Fajr angle of 20°, an Isha angle of 18°, the Shafi'i madhab
/// and a two-minute ihtiyati (safety margin) for every prayer. The angles are
/// set explicitly instead of trusting a preset, because the calculation now
/// runs for arbitrary kecamatan/desa coordinates rather than major cities.
class AdhanPrayerTimesDataSource {
  AdhanPrayerTimesDataSource() {
    tz_data.initializeTimeZones();
  }

  static const int _daysToCalculate = 7;
  static const int _ihtiyatiMinutes = 2;

  PrayerSchedule calculate({
    required String locationLabel,
    required double latitude,
    required double longitude,
    required String timeZoneId,
    DateTime? now,
  }) {
    final location = _location(timeZoneId);
    final resolvedTimeZoneId = location.name;
    final localNow = now == null
        ? tz.TZDateTime.now(location)
        : tz.TZDateTime.from(now, location);

    final parameters = _parameters();
    final days = <PrayerDay>[];

    for (var offset = 0; offset < _daysToCalculate; offset++) {
      final civilDate = DateTime(
        localNow.year,
        localNow.month,
        localNow.day,
      ).add(Duration(days: offset));

      final times = adhan.PrayerTimes.utc(
        adhan.Coordinates(latitude, longitude, validate: true),
        adhan.DateComponents(civilDate.year, civilDate.month, civilDate.day),
        parameters,
      );

      days.add(
        PrayerDay(
          date: DateTime.utc(civilDate.year, civilDate.month, civilDate.day),
          moments: [
            _moment(Prayer.fajr, times.fajr),
            _moment(Prayer.dhuhr, times.dhuhr),
            _moment(Prayer.asr, times.asr),
            _moment(Prayer.maghrib, times.maghrib),
            _moment(Prayer.isha, times.isha),
          ],
        ),
      );
    }

    return PrayerSchedule(
      locationLabel: locationLabel,
      timeZoneId: resolvedTimeZoneId,
      days: days,
      calculatedAt: (now ?? DateTime.now()).toUtc(),
    );
  }

  adhan.CalculationParameters _parameters() {
    // The Singapore preset shares Kemenag's 20°/18° angles; both are set here
    // so a dependency update cannot silently change the Indonesian standard.
    final parameters = adhan.CalculationMethod.singapore.getParameters();
    parameters.fajrAngle = 20;
    parameters.ishaAngle = 18;
    parameters.madhab = adhan.Madhab.shafi;
    parameters.adjustments
      ..fajr = _ihtiyatiMinutes
      ..dhuhr = _ihtiyatiMinutes
      ..asr = _ihtiyatiMinutes
      ..maghrib = _ihtiyatiMinutes
      ..isha = _ihtiyatiMinutes;
    return parameters;
  }

  PrayerMoment _moment(Prayer prayer, DateTime time) {
    return PrayerMoment(prayer: prayer, instant: time.toUtc());
  }

  tz.Location _location(String timeZoneId) {
    try {
      return tz.getLocation(timeZoneId);
    } catch (_) {
      return tz.getLocation('Asia/Jakarta');
    }
  }
}
