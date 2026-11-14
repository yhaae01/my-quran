import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/detected_location.dart';
import '../../domain/entities/mushaf.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_city.dart';
import '../../domain/entities/prayer_preferences.dart';
import 'core_providers.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return ref.watch(settingsRepositoryProvider).load();
  }

  void setArabicFontSize(double size) {
    final clamped = size
        .clamp(AppSettings.minArabicFontSize, AppSettings.maxArabicFontSize)
        .toDouble();
    if (clamped == state.arabicFontSize) return;
    _update(state.copyWith(arabicFontSize: clamped));
  }

  void setShowTranslation(bool show) {
    if (show == state.showTranslation) return;
    _update(state.copyWith(showTranslation: show));
  }

  void toggleTranslation() => setShowTranslation(!state.showTranslation);

  void setMushafStyle(MushafStyle style) {
    if (style == state.mushafStyle) return;
    _update(state.copyWith(mushafStyle: style));
  }

  void setThemeMode(AppThemeMode mode) {
    if (mode == state.themeMode) return;
    _update(state.copyWith(themeMode: mode));
  }

  void setPrayerNotificationsEnabled(bool enabled) {
    if (enabled == state.prayer.notificationsEnabled) return;
    _update(
      state.copyWith(
        prayer: state.prayer.copyWith(notificationsEnabled: enabled),
      ),
    );
  }

  void setPrayerEnabled(Prayer prayer, bool enabled) {
    final next = {...state.prayer.enabledPrayers};
    if (enabled) {
      next.add(prayer);
    } else {
      next.remove(prayer);
    }
    if (next.length == state.prayer.enabledPrayers.length &&
        next.containsAll(state.prayer.enabledPrayers)) {
      return;
    }
    _update(
      state.copyWith(prayer: state.prayer.copyWith(enabledPrayers: next)),
    );
  }

  void setPrayerCity(String cityId) {
    final city = prayerCityById(cityId);
    if (city.id == state.prayer.cityId &&
        state.prayer.locationMode == PrayerLocationMode.city) {
      return;
    }
    _update(
      state.copyWith(
        prayer: state.prayer.copyWith(
          cityId: city.id,
          locationMode: PrayerLocationMode.city,
        ),
      ),
    );
  }

  void setPrayerLocationMode(PrayerLocationMode mode) {
    if (mode == state.prayer.locationMode) return;
    _update(state.copyWith(prayer: state.prayer.copyWith(locationMode: mode)));
  }

  void setDevicePrayerLocation(DetectedLocation location) {
    _update(
      state.copyWith(
        prayer: state.prayer.copyWith(
          locationMode: PrayerLocationMode.automatic,
          latitude: location.latitude,
          longitude: location.longitude,
          timeZoneId: location.timeZoneId,
          locationLabel: location.label,
        ),
      ),
    );
  }

  void _update(AppSettings next) {
    state = next;
    unawaited(ref.read(settingsRepositoryProvider).save(next));
  }
}

final NotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
