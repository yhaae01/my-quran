import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/error/failure.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_preferences.dart';

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
      final payload = _buildPayload(schedule);
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
    } catch (error) {
      debugPrint('Widget waktu shalat gagal diperbarui: $error');
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

  Map<String, Object?> _buildPayload(PrayerSchedule schedule) {
    final location = tz.getLocation(schedule.timeZoneId);
    return {
      'location': schedule.locationLabel,
      'timeZoneId': schedule.timeZoneId,
      'updatedAt': schedule.calculatedAt.toUtc().toIso8601String(),
      'moments': [
        for (final moment in schedule.moments)
          {
            'prayer': moment.prayer.name,
            'label': moment.prayer.label,
            'epochMs': moment.instant.millisecondsSinceEpoch,
            'time': _clock(moment, location),
          },
      ],
    };
  }

  String _clock(PrayerMoment moment, tz.Location location) {
    final local = tz.TZDateTime.from(moment.instant, location);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
