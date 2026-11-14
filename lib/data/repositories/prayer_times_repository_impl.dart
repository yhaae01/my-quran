import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_preferences.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../datasources/adhan_prayer_times_data_source.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  PrayerTimesRepositoryImpl(this._dataSource);

  final AdhanPrayerTimesDataSource _dataSource;

  @override
  PrayerSchedule scheduleFor(PrayerPreferences preferences, {DateTime? now}) {
    return _dataSource.calculate(
      locationLabel: preferences.resolvedLocationLabel,
      latitude: preferences.resolvedLatitude,
      longitude: preferences.resolvedLongitude,
      timeZoneId: preferences.resolvedTimeZoneId,
      now: now,
    );
  }
}
