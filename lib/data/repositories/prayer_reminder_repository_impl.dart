import '../../core/error/failure.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_preferences.dart';
import '../../domain/repositories/prayer_reminder_repository.dart';
import '../datasources/prayer_notification_data_source.dart';

class PrayerReminderRepositoryImpl implements PrayerReminderRepository {
  PrayerReminderRepositoryImpl(this._dataSource);

  final PrayerNotificationDataSource _dataSource;

  @override
  Future<bool> requestPermission() async {
    try {
      return await _dataSource.requestPermission();
    } catch (error) {
      throw prayerNotificationFailure(error);
    }
  }

  @override
  Future<void> sync(
    PrayerSchedule schedule,
    PrayerPreferences preferences,
  ) async {
    try {
      await _dataSource.sync(schedule, preferences);
    } catch (error) {
      throw prayerNotificationFailure(error);
    }
  }
}

/// Small helper so the presentation layer can show a readable message.
Failure prayerFailure(Object error) {
  if (error is Failure) return error;
  return Failure(error.toString());
}
