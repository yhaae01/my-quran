import '../entities/prayer.dart';
import '../entities/prayer_preferences.dart';

abstract interface class PrayerReminderRepository {
  /// Asks the platform for notification and exact-alarm permission.
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with the prayers enabled in
  /// [preferences].
  Future<void> sync(PrayerSchedule schedule, PrayerPreferences preferences);
}
