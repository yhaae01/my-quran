import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/error/failure.dart';
import '../../core/utils/hijri_utils.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_preferences.dart';
import 'adhan_prayer_times_data_source.dart';

/// Pushes the next prayers and a countdown target to the Android/iOS widget.
class PrayerWidgetDataSource {
  static const String androidProvider = 'PrayerTimesWidgetProvider';
  static const String iOSWidgetKind = 'PrayerTimesWidget';
  static const String payloadKey = 'prayer_widget_payload';
  static const String _iOsAppGroup = 'group.com.example.myQuran.prayer';

  bool _configured = false;

  PrayerWidgetDataSource() {
    tz_data.initializeTimeZones();
  }

  Future<void> update(
    PrayerSchedule schedule,
    PrayerPreferences preferences,
  ) async {
    if (kIsWeb) return;
    await _configure();
    try {
      await _saveAndRefresh(
        schedule,
        latitude: preferences.resolvedLatitude,
        longitude: preferences.resolvedLongitude,
      );
    } catch (error) {
      debugPrint('Widget waktu shalat gagal diperbarui: $error');
    }
  }

  /// Recomputes the widget schedule from the coordinates stored in the last
  /// payload. Used by the background isolate when the user taps refresh, so the
  /// widget keeps working without opening the app or reading Hive boxes.
  Future<void> refreshFromStoredData() async {
    if (kIsWeb) return;
    await _configure();

    final stored = await _readStoredPayload();
    final latitude =
        stored?.latitude ?? defaultPrayerPreferences.resolvedLatitude;
    final longitude =
        stored?.longitude ?? defaultPrayerPreferences.resolvedLongitude;
    final timeZoneId =
        stored?.timeZoneId ?? defaultPrayerPreferences.resolvedTimeZoneId;
    final location =
        stored?.location ?? defaultPrayerPreferences.resolvedLocationLabel;

    final schedule = AdhanPrayerTimesDataSource().calculate(
      locationLabel: location,
      latitude: latitude,
      longitude: longitude,
      timeZoneId: timeZoneId,
    );
    await _saveAndRefresh(schedule, latitude: latitude, longitude: longitude);
  }

  /// Writes a valid placeholder schedule so the native widget never has to
  /// draw an empty card when the app data is temporarily unavailable.
  Future<void> writeFallbackPayload() async {
    if (kIsWeb) return;
    await _configure();
    final preferences = defaultPrayerPreferences;
    final schedule = AdhanPrayerTimesDataSource().calculate(
      locationLabel: preferences.resolvedLocationLabel,
      latitude: preferences.resolvedLatitude,
      longitude: preferences.resolvedLongitude,
      timeZoneId: preferences.resolvedTimeZoneId,
    );
    await _saveAndRefresh(
      schedule,
      latitude: preferences.resolvedLatitude,
      longitude: preferences.resolvedLongitude,
    );
  }

  Future<_StoredWidgetData?> _readStoredPayload() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>(payloadKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return _StoredWidgetData(
        location: decoded['location'] as String?,
        timeZoneId: decoded['timeZoneId'] as String?,
        latitude: (decoded['latitude'] as num?)?.toDouble(),
        longitude: (decoded['longitude'] as num?)?.toDouble(),
      );
    } catch (error) {
      debugPrint('Data widget tersimpan tidak dapat dibaca: $error');
      return null;
    }
  }

  Future<void> _saveAndRefresh(
    PrayerSchedule schedule, {
    required double latitude,
    required double longitude,
  }) async {
    final payload = _buildPayload(
      schedule,
      latitude: latitude,
      longitude: longitude,
    );
    await HomeWidget.saveWidgetData<String>(payloadKey, jsonEncode(payload));
    await HomeWidget.updateWidget(
      androidName: androidProvider,
      iOSName: iOSWidgetKind,
    );

    final upcoming = schedule.moments
        .where((moment) => moment.instant.isAfter(DateTime.now()))
        .map((moment) => moment.instant)
        .toList();
    if (upcoming.isNotEmpty) {
      await HomeWidget.scheduleWidgetUpdates(
        upcoming,
        androidName: androidProvider,
      );
    }
  }

  Future<bool> canPin() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pin() async {
    try {
      await HomeWidget.requestPinWidget(androidName: androidProvider);
      return true;
    } catch (error) {
      throw Failure('Widget tidak bisa dipasang: $error');
    }
  }

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await HomeWidget.setAppGroupId(_iOsAppGroup);
    } catch (error) {
      debugPrint('App group widget tidak tersedia: $error');
    }
  }

  Map<String, Object?> _buildPayload(
    PrayerSchedule schedule, {
    required double latitude,
    required double longitude,
  }) {
    final location = tz.getLocation(schedule.timeZoneId);
    return {
      'location': schedule.locationLabel,
      'timeZoneId': schedule.timeZoneId,
      // Kept inside the payload so the background isolate can recalculate the
      // schedule without Hive or a running ProviderScope.
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': schedule.calculatedAt.toUtc().toIso8601String(),
      // The widget needs today's five times to draw its full row, and the
      // native side picks the right day when the app is not opened.
      'hijriDate': formatHijriDate(schedule.today.date),
      'days': [
        for (final day in schedule.days)
          {
            'date': _dateKey(day.date),
            'hijriDate': formatHijriDate(day.date),
            'prayers': [
              for (final moment in day.moments) _momentJson(moment, location),
            ],
          },
      ],
      'moments': [
        for (final moment in schedule.moments) _momentJson(moment, location),
      ],
    };
  }

  Map<String, Object?> _momentJson(PrayerMoment moment, tz.Location location) {
    return {
      'prayer': moment.prayer.name,
      'label': moment.prayer.label,
      'epochMs': moment.instant.millisecondsSinceEpoch,
      'time': _clock(moment, location),
    };
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static const PrayerPreferences defaultPrayerPreferences = PrayerPreferences();

  String _clock(PrayerMoment moment, tz.Location location) {
    final local = tz.TZDateTime.from(moment.instant, location);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _StoredWidgetData {
  const _StoredWidgetData({
    this.location,
    this.timeZoneId,
    this.latitude,
    this.longitude,
  });

  final String? location;
  final String? timeZoneId;
  final double? latitude;
  final double? longitude;
}
