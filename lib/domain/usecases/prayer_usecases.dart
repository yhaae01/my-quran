import '../entities/detected_location.dart';
import '../entities/prayer.dart';
import '../entities/prayer_preferences.dart';
import '../repositories/location_repository.dart';
import '../repositories/prayer_reminder_repository.dart';
import '../repositories/prayer_times_repository.dart';
import '../repositories/prayer_widget_repository.dart';

class GetPrayerSchedule {
  const GetPrayerSchedule(this._repository);

  final PrayerTimesRepository _repository;

  PrayerSchedule call(PrayerPreferences preferences, {DateTime? now}) {
    return _repository.scheduleFor(preferences, now: now);
  }
}

class DetectCurrentLocation {
  const DetectCurrentLocation(this._repository);

  final LocationRepository _repository;

  Future<DetectedLocation> call() => _repository.detectCurrent();
}

class RequestPrayerNotificationPermission {
  const RequestPrayerNotificationPermission(this._repository);

  final PrayerReminderRepository _repository;

  Future<bool> call() => _repository.requestPermission();
}

class SyncPrayerReminders {
  const SyncPrayerReminders(this._repository);

  final PrayerReminderRepository _repository;

  Future<void> call(PrayerSchedule schedule, PrayerPreferences preferences) =>
      _repository.sync(schedule, preferences);
}

class SyncPrayerWidget {
  const SyncPrayerWidget(this._repository);

  final PrayerWidgetRepository _repository;

  Future<void> call(PrayerSchedule schedule, PrayerPreferences preferences) =>
      _repository.sync(schedule, preferences);

  Future<bool> canPin() => _repository.canPin();

  Future<void> pin() => _repository.pin();
}
