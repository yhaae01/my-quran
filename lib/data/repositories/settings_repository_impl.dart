import 'package:hive/hive.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/mushaf.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_city.dart';
import '../../domain/entities/prayer_preferences.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._box);

  final Box<dynamic> _box;

  static const String _fontSizeKey = 'arabic_font_size';
  static const String _showTranslationKey = 'show_translation';
  static const String _mushafStyleKey = 'mushaf_style';
  static const String _themeModeKey = 'theme_mode';
  static const String _prayerNotificationsKey = 'prayer_notifications_enabled';
  static const String _prayerEnabledKey = 'prayer_enabled_prayers';
  static const String _prayerLocationModeKey = 'prayer_location_mode';
  static const String _prayerCityKey = 'prayer_city_id';
  static const String _prayerLatitudeKey = 'prayer_latitude';
  static const String _prayerLongitudeKey = 'prayer_longitude';
  static const String _prayerTimeZoneKey = 'prayer_timezone_id';
  static const String _prayerLabelKey = 'prayer_location_label';
  static const String _prayerRegionIdKey = 'prayer_region_id';
  static const String _prayerVillageIdKey = 'prayer_village_id';
  static const String _prayerRegionLabelKey = 'prayer_region_label';
  static const String _prayerRegionLatitudeKey = 'prayer_region_latitude';
  static const String _prayerRegionLongitudeKey = 'prayer_region_longitude';
  static const String _prayerRegionTimeZoneKey = 'prayer_region_timezone_id';
  static const String _reciterIdKey = 'reciter_id';

  @override
  AppSettings load() {
    final storedSize = _box.get(_fontSizeKey);
    final storedShowTranslation = _box.get(_showTranslationKey);
    final storedStyle = _box.get(_mushafStyleKey);
    final storedThemeMode = _box.get(_themeModeKey);
    final storedNotifications = _box.get(_prayerNotificationsKey);
    final storedEnabled = _box.get(_prayerEnabledKey);
    final storedLocationMode = _box.get(_prayerLocationModeKey);
    final storedCity = _box.get(_prayerCityKey);
    final storedLatitude = _box.get(_prayerLatitudeKey);
    final storedLongitude = _box.get(_prayerLongitudeKey);
    final storedTimeZone = _box.get(_prayerTimeZoneKey);
    final storedLabel = _box.get(_prayerLabelKey);
    final storedRegionId = _box.get(_prayerRegionIdKey);
    final storedVillageId = _box.get(_prayerVillageIdKey);
    final storedRegionLabel = _box.get(_prayerRegionLabelKey);
    final storedRegionLatitude = _box.get(_prayerRegionLatitudeKey);
    final storedRegionLongitude = _box.get(_prayerRegionLongitudeKey);
    final storedRegionTimeZone = _box.get(_prayerRegionTimeZoneKey);
    final storedReciter = _box.get(_reciterIdKey);

    final fontSize = storedSize is num
        ? storedSize
              .toDouble()
              .clamp(
                AppSettings.minArabicFontSize,
                AppSettings.maxArabicFontSize,
              )
              .toDouble()
        : AppSettings.defaultArabicFontSize;

    return AppSettings(
      arabicFontSize: fontSize,
      showTranslation: storedShowTranslation is bool
          ? storedShowTranslation
          : true,
      mushafStyle: storedStyle is String
          ? MushafStyle.fromId(storedStyle)
          : MushafStyle.kemenag,
      themeMode: AppThemeMode.fromName(
        storedThemeMode is String ? storedThemeMode : null,
      ),
      prayer: PrayerPreferences(
        notificationsEnabled: storedNotifications is bool
            ? storedNotifications
            : false,
        enabledPrayers: _loadEnabledPrayers(storedEnabled),
        locationMode: _loadLocationMode(storedLocationMode),
        cityId: storedCity is String
            ? prayerCityById(storedCity).id
            : defaultPrayerCity.id,
        latitude: storedLatitude is num ? storedLatitude.toDouble() : null,
        longitude: storedLongitude is num ? storedLongitude.toDouble() : null,
        timeZoneId: storedTimeZone is String ? storedTimeZone : null,
        locationLabel: storedLabel is String ? storedLabel : null,
        regionId: storedRegionId is String ? storedRegionId : null,
        villageId: storedVillageId is String ? storedVillageId : null,
        regionLabel: storedRegionLabel is String ? storedRegionLabel : null,
        regionLatitude: storedRegionLatitude is num
            ? storedRegionLatitude.toDouble()
            : null,
        regionLongitude: storedRegionLongitude is num
            ? storedRegionLongitude.toDouble()
            : null,
        regionTimeZoneId: storedRegionTimeZone is String
            ? storedRegionTimeZone
            : null,
      ),
      reciterId: Reciter.fromId(storedReciter is String ? storedReciter : null)
          .id,
    );
  }

  Set<Prayer> _loadEnabledPrayers(Object? stored) {
    if (stored is! List) return PrayerPreferences.allPrayers;
    final prayers = stored
        .whereType<String>()
        .map(Prayer.fromName)
        .whereType<Prayer>()
        .toSet();
    return prayers;
  }

  PrayerLocationMode _loadLocationMode(Object? stored) {
    for (final mode in PrayerLocationMode.values) {
      if (mode.name == stored) return mode;
    }
    return PrayerLocationMode.city;
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _box.put(_fontSizeKey, settings.arabicFontSize);
    await _box.put(_showTranslationKey, settings.showTranslation);
    await _box.put(_mushafStyleKey, settings.mushafStyle.id);
    await _box.put(_themeModeKey, settings.themeMode.name);
    await _box.put(_reciterIdKey, settings.reciter.id);

    final prayer = settings.prayer;
    await _box.put(_prayerNotificationsKey, prayer.notificationsEnabled);
    await _box.put(
      _prayerEnabledKey,
      prayer.enabledPrayers.map((item) => item.name).toList(),
    );
    await _box.put(_prayerLocationModeKey, prayer.locationMode.name);
    await _box.put(_prayerCityKey, prayer.cityId);
    await _box.put(_prayerLatitudeKey, prayer.latitude);
    await _box.put(_prayerLongitudeKey, prayer.longitude);
    await _box.put(_prayerTimeZoneKey, prayer.timeZoneId);
    await _box.put(_prayerLabelKey, prayer.locationLabel);
    await _box.put(_prayerRegionIdKey, prayer.regionId);
    await _box.put(_prayerVillageIdKey, prayer.villageId);
    await _box.put(_prayerRegionLabelKey, prayer.regionLabel);
    await _box.put(_prayerRegionLatitudeKey, prayer.regionLatitude);
    await _box.put(_prayerRegionLongitudeKey, prayer.regionLongitude);
    await _box.put(_prayerRegionTimeZoneKey, prayer.regionTimeZoneId);
  }
}
