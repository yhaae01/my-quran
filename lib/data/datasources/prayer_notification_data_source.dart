import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/error/failure.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_preferences.dart';

/// Schedules and cancels the adhan reminder notifications.
class PrayerNotificationDataSource {
  PrayerNotificationDataSource([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  static const int _idBase = 4100;
  static const int _daysAhead = 7;

  Future<void> sync(
    PrayerSchedule schedule,
    PrayerPreferences preferences,
  ) async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _cancelOwned();

    if (!preferences.notificationsEnabled) return;

    final location = tz.getLocation(schedule.timeZoneId);
    final now = DateTime.now();
    final android = _android;
    final canScheduleExact = android == null
        ? false
        : await android.canScheduleExactNotifications();
    final mode = canScheduleExact == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (var dayIndex = 0; dayIndex < schedule.days.length; dayIndex++) {
      final day = schedule.days[dayIndex];
      for (final moment in day.moments) {
        if (!preferences.enabledPrayers.contains(moment.prayer)) continue;
        if (!moment.instant.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: _idBase + dayIndex * 10 + moment.prayer.index,
          scheduledDate: tz.TZDateTime.from(moment.instant, location),
          title: 'Waktu ${moment.prayer.label}',
          body:
              'Sudah masuk waktu shalat ${moment.prayer.label}. '
              '${moment.prayer.arabicLabel}',
          notificationDetails: _details,
          androidScheduleMode: mode,
          payload: 'prayer:${moment.prayer.name}',
        );
      }
    }
  }

  Future<bool> requestPermission() async {
    await _ensureInitialized();
    if (kIsWeb) return false;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final granted =
            await _android?.requestNotificationsPermission() ?? false;
        if (granted) {
          await _android?.requestExactAlarmsPermission();
        }
        return granted;
      case TargetPlatform.iOS:
        return await _ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      default:
        return false;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_logo'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    // Android caches a channel's icon once it has been created, so remove the
    // legacy channel and let the v2 channel be created with the app logo.
    try {
      await _android?.deleteNotificationChannel(channelId: 'prayer_times');
    } catch (_) {
      // Channel may not exist yet.
    }
    _initialized = true;
  }

  Future<void> _cancelOwned() async {
    for (var id = _idBase; id < _idBase + _daysAhead * 10; id++) {
      await _plugin.cancel(id: id);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_times_v2',
      'Waktu Shalat',
      channelDescription: 'Pengingat saat waktu shalat tiba',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      enableVibration: true,
      playSound: true,
      icon: 'ic_stat_logo',
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );
}

/// Ensures scheduler failures never surface as raw platform exceptions.
Failure prayerNotificationFailure(Object error) {
  final message = error is PlatformException ? error.message : '$error';
  return Failure('Pengingat shalat gagal dijadwalkan: $message');
}
