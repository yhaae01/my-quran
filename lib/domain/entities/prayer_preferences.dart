import 'prayer.dart';
import 'prayer_city.dart';

enum PrayerLocationMode {
  automatic,
  city;

  String get label => switch (this) {
    PrayerLocationMode.automatic => 'Lokasi saat ini',
    PrayerLocationMode.city => 'Wilayah pilihan',
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
    this.regionId,
    this.villageId,
    this.regionLabel,
    this.regionLatitude,
    this.regionLongitude,
    this.regionTimeZoneId,
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

  /// Legacy major-city id, still used when no kecamatan has been chosen.
  final String cityId;

  /// Last GPS fix. Kept so automatic mode still works offline.
  final double? latitude;
  final double? longitude;
  final String? timeZoneId;
  final String? locationLabel;

  /// Selected kecamatan (and optionally desa/kelurahan) from the bundled
  /// region catalog. Coordinates are stored directly so manual mode never has
  /// to parse the region asset just to calculate prayer times.
  final String? regionId;
  final String? villageId;
  final String? regionLabel;
  final double? regionLatitude;
  final double? regionLongitude;
  final String? regionTimeZoneId;

  bool get hasAutomaticFix =>
      latitude != null && longitude != null && timeZoneId != null;

  bool get hasRegion =>
      regionId != null &&
      regionLatitude != null &&
      regionLongitude != null &&
      regionTimeZoneId != null;

  bool get _usesAutomaticFix =>
      locationMode == PrayerLocationMode.automatic && hasAutomaticFix;

  bool get _usesRegion => locationMode == PrayerLocationMode.city && hasRegion;

  PrayerCity get city => prayerCityById(cityId);

  /// Location used by the calculator, including the GPS fix label.
  double get resolvedLatitude => _usesAutomaticFix
      ? latitude!
      : _usesRegion
      ? regionLatitude!
      : city.latitude;

  double get resolvedLongitude => _usesAutomaticFix
      ? longitude!
      : _usesRegion
      ? regionLongitude!
      : city.longitude;

  String get resolvedTimeZoneId => _usesAutomaticFix
      ? timeZoneId!
      : _usesRegion
      ? regionTimeZoneId!
      : city.timeZoneId;

  String get resolvedLocationLabel => _usesAutomaticFix
      ? locationLabel ?? 'Lokasi saat ini'
      : _usesRegion
      ? regionLabel ?? 'Wilayah pilihan'
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
    String? regionId,
    String? villageId,
    bool clearVillage = false,
    String? regionLabel,
    double? regionLatitude,
    double? regionLongitude,
    String? regionTimeZoneId,
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
      regionId: regionId ?? this.regionId,
      villageId: clearVillage ? null : villageId ?? this.villageId,
      regionLabel: regionLabel ?? this.regionLabel,
      regionLatitude: regionLatitude ?? this.regionLatitude,
      regionLongitude: regionLongitude ?? this.regionLongitude,
      regionTimeZoneId: regionTimeZoneId ?? this.regionTimeZoneId,
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
        other.locationLabel == locationLabel &&
        other.regionId == regionId &&
        other.villageId == villageId &&
        other.regionLabel == regionLabel &&
        other.regionLatitude == regionLatitude &&
        other.regionLongitude == regionLongitude &&
        other.regionTimeZoneId == regionTimeZoneId;
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
    regionId,
    villageId,
    regionLabel,
    regionLatitude,
    regionLongitude,
    regionTimeZoneId,
  );
}
