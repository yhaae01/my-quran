import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_quran/core/utils/prayer_utils.dart';
import 'package:my_quran/data/datasources/adhan_prayer_times_data_source.dart';
import 'package:my_quran/data/repositories/settings_repository_impl.dart';
import 'package:my_quran/domain/entities/app_settings.dart';
import 'package:my_quran/domain/entities/prayer.dart';
import 'package:my_quran/domain/entities/prayer_city.dart';
import 'package:my_quran/domain/entities/prayer_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

PrayerSchedule _scheduleForJakarta({DateTime? now}) {
  return AdhanPrayerTimesDataSource().calculate(
    locationLabel: 'Jakarta',
    latitude: defaultPrayerCity.latitude,
    longitude: defaultPrayerCity.longitude,
    timeZoneId: defaultPrayerCity.timeZoneId,
    now: now ?? DateTime.utc(2026, 11, 14, 2),
  );
}

PrayerSchedule _syntheticSchedule() {
  final base = DateTime.utc(2026, 11, 14, 3);
  return PrayerSchedule(
    locationLabel: 'Uji',
    timeZoneId: 'Asia/Jakarta',
    calculatedAt: base,
    days: [
      PrayerDay(
        date: DateTime.utc(2026, 11, 14),
        moments: [
          for (var index = 0; index < Prayer.values.length; index++)
            PrayerMoment(
              prayer: Prayer.values[index],
              instant: base.add(Duration(hours: index)),
            ),
        ],
      ),
      PrayerDay(
        date: DateTime.utc(2026, 11, 15),
        moments: [
          for (var index = 0; index < Prayer.values.length; index++)
            PrayerMoment(
              prayer: Prayer.values[index],
              instant: base.add(Duration(days: 1, hours: index)),
            ),
        ],
      ),
    ],
  );
}

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('Adhan calculation', () {
    test('builds seven consecutive days with five prayers each', () {
      final schedule = _scheduleForJakarta();

      expect(schedule.days, hasLength(7));
      expect(schedule.days.first.date, DateTime.utc(2026, 11, 14));
      expect(schedule.days.last.date, DateTime.utc(2026, 11, 20));
      for (final day in schedule.days) {
        expect(day.moments.map((moment) => moment.prayer), Prayer.values);
      }
    });

    test('prays fall in the expected Jakarta windows', () {
      final schedule = _scheduleForJakarta();
      final location = tz.getLocation('Asia/Jakarta');
      final local = {
        for (final moment in schedule.today.moments)
          moment.prayer: tz.TZDateTime.from(moment.instant, location),
      };

      expect(local[Prayer.fajr]!.hour, inInclusiveRange(3, 5));
      expect(local[Prayer.dhuhr]!.hour, inInclusiveRange(11, 13));
      expect(local[Prayer.asr]!.hour, inInclusiveRange(14, 17));
      expect(local[Prayer.maghrib]!.hour, inInclusiveRange(17, 19));
      expect(local[Prayer.isha]!.hour, inInclusiveRange(18, 21));
      expect(local[Prayer.fajr]!.isBefore(local[Prayer.dhuhr]!), isTrue);
      expect(local[Prayer.dhuhr]!.isBefore(local[Prayer.asr]!), isTrue);
      expect(local[Prayer.asr]!.isBefore(local[Prayer.maghrib]!), isTrue);
      expect(local[Prayer.maghrib]!.isBefore(local[Prayer.isha]!), isTrue);
    });

    test(
      'stores absolute instants and formats clocks in the city timezone',
      () {
        final schedule = _scheduleForJakarta();
        final fajr = schedule.today.momentFor(Prayer.fajr);
        expect(fajr.instant.isUtc, isTrue);

        final clock = formatPrayerClock(fajr, schedule.timeZoneId);
        expect(clock, matches(RegExp(r'^\d{2}:\d{2}$')));
        expect(clock, '04:05');
      },
    );

    test('uses WITA for Makassar instead of the device timezone', () {
      final schedule = AdhanPrayerTimesDataSource().calculate(
        locationLabel: 'Makassar',
        latitude: -5.1477,
        longitude: 119.4327,
        timeZoneId: 'Asia/Makassar',
        now: DateTime.utc(2026, 11, 14, 2),
      );
      final makassar = tz.getLocation('Asia/Makassar');
      final fajr = schedule.today.momentFor(Prayer.fajr);
      expect(tz.TZDateTime.from(fajr.instant, makassar).hour, 4);
      expect(schedule.timeZoneId, 'Asia/Makassar');
    });

    test('chooses the next prayer and countdown across midnight', () {
      final schedule = _scheduleForJakarta();
      final now = DateTime.utc(2026, 11, 14, 10, 30); // 17:30 WIB
      final next = schedule.nextAfter(now);

      expect(next?.prayer, Prayer.maghrib);
      expect(next!.instant.isAfter(now), isTrue);
      expect(schedule.countdownTo(now)!.inSeconds, greaterThan(0));

      final afterIsha = schedule.today
          .momentFor(Prayer.isha)
          .instant
          .add(const Duration(minutes: 1));
      final tomorrowFajr = schedule.nextAfter(afterIsha);
      expect(tomorrowFajr?.prayer, Prayer.fajr);
      expect(
        tomorrowFajr!.instant.isAfter(
          schedule.today.momentFor(Prayer.isha).instant,
        ),
        isTrue,
      );
    });
  });

  group('PrayerSchedule behaviour', () {
    test('reports the prayer window that is currently active', () {
      final schedule = _syntheticSchedule();
      expect(
        schedule.currentAt(DateTime.utc(2026, 11, 14, 4, 30))?.prayer,
        Prayer.dhuhr,
      );
      expect(
        schedule.nextAfter(DateTime.utc(2026, 11, 14, 4, 30))?.prayer,
        Prayer.asr,
      );
    });

    test('countdown is measured from now and never negative', () {
      final schedule = _syntheticSchedule();
      final now = DateTime.utc(2026, 11, 14, 3, 30);
      expect(schedule.countdownTo(now), const Duration(minutes: 30));
      expect(
        schedule.countdownTo(DateTime.utc(2026, 11, 20))!.inSeconds,
        greaterThanOrEqualTo(0),
      );
    });

    test('formats date and countdown for the UI', () {
      expect(
        formatPrayerDate(DateTime.utc(2026, 11, 14)),
        'Sabtu, 14 November 2026',
      );
      expect(
        formatCountdown(const Duration(hours: 2, minutes: 14, seconds: 9)),
        '02:14:09',
      );
      expect(formatCountdown(const Duration(minutes: 4, seconds: 3)), '04:03');
      expect(describeCountdown(const Duration(minutes: 1)), '1 menit');
      expect(
        describeCountdown(const Duration(hours: 1, minutes: 5)),
        '1 jam 5 menit',
      );
    });
  });

  group('Prayer city data', () {
    test('has unique ids and valid coordinates and timezones', () {
      final ids = <String>{};
      for (final city in indonesianPrayerCities) {
        expect(ids.add(city.id), isTrue, reason: 'duplicate ${city.id}');
        expect(city.latitude, inInclusiveRange(-11, 6));
        expect(city.longitude, inInclusiveRange(95, 141));
        expect(
          () => tz.getLocation(city.timeZoneId),
          returnsNormally,
          reason: city.timeZoneId,
        );
      }
      expect(prayerCityById('tidak-ada'), defaultPrayerCity);
    });
  });

  group('PrayerPreferences', () {
    test('resolves city coordinates until a GPS fix exists', () {
      const preferences = PrayerPreferences(cityId: 'bandung');
      expect(preferences.resolvedLatitude, prayerCityById('bandung').latitude);
      expect(preferences.resolvedLocationLabel, 'Bandung');
      expect(preferences.isPrayerEnabled(Prayer.fajr), isFalse);

      const automatic = PrayerPreferences(
        locationMode: PrayerLocationMode.automatic,
        latitude: -6.9,
        longitude: 107.6,
        timeZoneId: 'Asia/Jakarta',
        locationLabel: 'Lokasi saat ini',
        notificationsEnabled: true,
      );
      expect(automatic.resolvedLatitude, -6.9);
      expect(automatic.resolvedTimeZoneId, 'Asia/Jakarta');
      expect(automatic.isPrayerEnabled(Prayer.fajr), isTrue);
    });

    test('prefers a selected kecamatan over the legacy city', () {
      const preferences = PrayerPreferences(
        cityId: 'bandung',
        regionId: '3202210',
        regionLabel: 'Kec. Cibadak, Kabupaten Sukabumi',
        regionLatitude: -6.895,
        regionLongitude: 106.77,
        regionTimeZoneId: 'Asia/Jakarta',
      );

      expect(preferences.hasRegion, isTrue);
      expect(preferences.resolvedLatitude, -6.895);
      expect(preferences.resolvedLongitude, 106.77);
      expect(
        preferences.resolvedLocationLabel,
        'Kec. Cibadak, Kabupaten Sukabumi',
      );

      final automatic = preferences.copyWith(
        locationMode: PrayerLocationMode.automatic,
        latitude: -7.1,
        longitude: 107.4,
        timeZoneId: 'Asia/Jakarta',
        locationLabel: 'Kec. Ciwidey, Kabupaten Bandung (GPS)',
      );
      expect(automatic.resolvedLatitude, -7.1);
      expect(
        automatic.resolvedLocationLabel,
        'Kec. Ciwidey, Kabupaten Bandung (GPS)',
      );
    });

    test('disabled reminder list is preserved', () {
      const preferences = PrayerPreferences(
        notificationsEnabled: false,
        enabledPrayers: {},
      );
      expect(preferences.enabledPrayers, isEmpty);
      expect(preferences.isPrayerEnabled(Prayer.isha), isFalse);
    });
  });

  group('Prayer settings persistence', () {
    late Directory tempDir;
    late Box<dynamic> box;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('my_quran_prayer_test');
      Hive.init(tempDir.path);
      box = await Hive.openBox<dynamic>('prayer_settings_test');
    });

    setUp(() async {
      await box.clear();
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('defaults match the bundled Jakarta city', () {
      final settings = SettingsRepositoryImpl(box).load();
      expect(settings.prayer.cityId, defaultPrayerCity.id);
      expect(settings.prayer.locationMode, PrayerLocationMode.city);
      expect(settings.prayer.notificationsEnabled, isFalse);
      expect(settings.prayer.enabledPrayers, PrayerPreferences.allPrayers);
    });

    test('round-trips notifications, prayers and a GPS fix', () async {
      const preferences = PrayerPreferences(
        notificationsEnabled: true,
        enabledPrayers: {Prayer.fajr, Prayer.maghrib, Prayer.isha},
        locationMode: PrayerLocationMode.automatic,
        cityId: 'surabaya',
        latitude: -7.25,
        longitude: 112.75,
        timeZoneId: 'Asia/Jakarta',
        locationLabel: 'Lokasi saat ini',
      );

      await SettingsRepositoryImpl(box)
          .save(const AppSettings(prayer: preferences));

      final reloaded = SettingsRepositoryImpl(box).load().prayer;
      expect(reloaded, preferences);
      expect(reloaded.enabledPrayers, preferences.enabledPrayers);
    });

    test('round-trips a kecamatan and desa selection', () async {
      const preferences = PrayerPreferences(
        locationMode: PrayerLocationMode.city,
        cityId: 'bandung',
        regionId: '3204010',
        villageId: '3204010002',
        regionLabel: 'Desa/Kel. Ciwidey, Kec. Ciwidey',
        regionLatitude: -7.089,
        regionLongitude: 107.444,
        regionTimeZoneId: 'Asia/Jakarta',
      );

      await SettingsRepositoryImpl(box)
          .save(const AppSettings(prayer: preferences));

      final reloaded = SettingsRepositoryImpl(box).load().prayer;
      expect(reloaded, preferences);
      expect(reloaded.regionId, '3204010');
      expect(reloaded.villageId, '3204010002');
      expect(reloaded.resolvedLatitude, -7.089);
    });

    test('keeps an explicitly empty prayer selection', () async {
      await SettingsRepositoryImpl(box).save(
        const AppSettings(
          prayer: PrayerPreferences(
            notificationsEnabled: true,
            enabledPrayers: {},
          ),
        ),
      );

      final reloaded = SettingsRepositoryImpl(box).load().prayer;
      expect(reloaded.enabledPrayers, isEmpty);
    });
  });
}
