import '../entities/prayer.dart';
import '../entities/prayer_preferences.dart';

abstract interface class PrayerTimesRepository {
  /// Calculates a week of prayer times for the location chosen in
  /// [preferences], falling back to the bundled city when GPS is unavailable.
  PrayerSchedule scheduleFor(PrayerPreferences preferences, {DateTime? now});
}
