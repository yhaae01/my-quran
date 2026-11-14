import 'prayer.dart';
import 'prayer_city.dart';

enum PrayerLocationMode {
  automatic,
  city;

  String get label => switch (this) {
    PrayerLocationMode.automatic => 'Lokasi saat ini',
    PrayerLocationMode.city => 'Kota pilihan',
  };
}

/// Everything the prayer feature needs to remember between launches.
class PrayerPreferences {
  const PrayerPreferences({
    this.notificationsEnabled = false,
    this.enabledPrayers = allPrayers,
    this.locationMode = PrayerLocationMode.city,
    this.cityId = 'jakarta',
    this.latitude,
    this.longitude,
    this.timeZoneId,
    this.locationLabel,
  });

  static const Set<Prayer> allPrayers = {
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  };

  final bool notificationsEnabled;
  final Set<Prayer> enabledPrayers;
  final PrayerLocationMode locationMode;
  final String cityId;

  /// Last GPS fix. Kept so automatic mode still works offline.
  final double? latitude;
  final double? longitude;
  final String? timeZoneId;
  final String? locationLabel;

  bool get hasAutomaticFix =>
      latitude != null && longitude != null && timeZoneId != null;

  PrayerCity get city => prayerCityById(cityId);

  /// Location used by the calculator, including the GPS fix label.
  double get resolvedLatitude =>
      locationMode == PrayerLocationMode.automatic && hasAutomaticFix
      ? latitude!
      : city.latitude;

  double get resolvedLongitude =>
      locationMode == PrayerLocationMode.automatic && hasAutomaticFix
      ? longitude!
      : city.longitude;

  String get resolvedTimeZoneId =>
      locationMode == PrayerLocationMode.automatic && hasAutomaticFix
      ? timeZoneId!
      : city.timeZoneId;

  String get resolvedLocationLabel =>
      locationMode == PrayerLocationMode.automatic && hasAutomaticFix
      ? locationLabel ?? 'Lokasi saat ini'
      : city.name;

  bool isPrayerEnabled(Prayer prayer) =>
      notificationsEnabled && enabledPrayers.contains(prayer);

  PrayerPreferences copyWith({
    bool? notificationsEnabled,
    Set<Prayer>? enabledPrayers,
    PrayerLocationMode? locationMode,
    String? cityId,
    double? latitude,
    double? longitude,
    String? timeZoneId,
    String? locationLabel,
  }) {
    return PrayerPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
      locationMode: locationMode ?? this.locationMode,
      cityId: cityId ?? this.cityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      locationLabel: locationLabel ?? this.locationLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PrayerPreferences &&
        other.notificationsEnabled == notificationsEnabled &&
        other.enabledPrayers.length == enabledPrayers.length &&
        other.enabledPrayers.containsAll(enabledPrayers) &&
        other.locationMode == locationMode &&
        other.cityId == cityId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timeZoneId == timeZoneId &&
        other.locationLabel == locationLabel;
  }

  @override
  int get hashCode => Object.hash(
    notificationsEnabled,
    Object.hashAllUnordered(enabledPrayers),
    locationMode,
    cityId,
    latitude,
    longitude,
    timeZoneId,
    locationLabel,
  );
}
