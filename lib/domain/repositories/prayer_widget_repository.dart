import '../entities/prayer.dart';
import '../entities/prayer_preferences.dart';

abstract interface class PrayerWidgetRepository {
  /// Stores the schedule for the home screen widget and schedules its updates.
  Future<void> sync(PrayerSchedule schedule, PrayerPreferences preferences);

  Future<bool> canPin();

  Future<void> pin();
}
