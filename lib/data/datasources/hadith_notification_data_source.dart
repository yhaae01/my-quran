import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/hadith.dart';
import '../../domain/repositories/hadith_repository.dart';

/// Schedules and manages the daily 05:00 AM Hadith notification.
class HadithNotificationDataSource {
  HadithNotificationDataSource([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const int idBase = 5000;
  static const int daysAhead = 7;

  /// Calculates the next occurrence of 05:00 AM in the given [location].
  /// If the current time is before 05:00 AM, returns today at 05:00 AM.
  /// Otherwise, returns tomorrow at 05:00 AM.
  tz.TZDateTime nextInstanceOf5AM(tz.Location location, [DateTime? fromDate]) {
    final now = tz.TZDateTime.from(fromDate ?? DateTime.now(), location);
    var scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      5, // 05:00 AM
      0,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedules daily 05:00 AM notifications for the upcoming [daysAhead] days,
  /// assigning a randomly selected hadith from [hadiths] for each morning.
  Future<void> scheduleDailyHadiths({
    required List<Hadith> hadiths,
    String? timeZoneId,
    DateTime? fromDate,
    Random? random,
  }) async {
    if (kIsWeb || hadiths.isEmpty) return;
    await _ensureInitialized();
    await cancelAll();

    final location = _resolveLocation(timeZoneId);
    final firstScheduled = nextInstanceOf5AM(location, fromDate);

    final android = _android;
    final canScheduleExact = android == null
        ? false
        : await android.canScheduleExactNotifications();
    final mode = canScheduleExact == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final rng = random ?? Random();

    for (var i = 0; i < daysAhead; i++) {
      final scheduledDate = firstScheduled.add(Duration(days: i));
      final hadith = getRandomHadithFromList(hadiths, rng);

      await _plugin.zonedSchedule(
        id: idBase + i,
        scheduledDate: scheduledDate,
        title: 'Hadis Hari Ini',
        body: hadith.translation,
        notificationDetails: _buildDetails(hadith),
        androidScheduleMode: mode,
        matchDateTimeComponents: i == 0 ? DateTimeComponents.time : null,
        payload: 'hadith:${hadith.book}:${hadith.number}',
      );
    }
  }

  /// Cancels all scheduled Hadith notifications.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    for (var id = idBase; id < idBase + daysAhead + 1; id++) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_adhan'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  tz.Location _resolveLocation(String? timeZoneId) {
    if (timeZoneId != null && timeZoneId.isNotEmpty) {
      try {
        return tz.getLocation(timeZoneId);
      } catch (_) {}
    }
    return tz.local;
  }

  NotificationDetails _buildDetails(Hadith hadith) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_hadith',
        'Hadis Hari Ini',
        channelDescription:
            'Notifikasi hadis pilihan setiap hari pukul 05:00 pagi',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        playSound: true,
        icon: 'ic_stat_adhan',
        styleInformation: BigTextStyleInformation(
          hadith.translation,
          contentTitle: 'Hadis Hari Ini',
          summaryText: hadith.reference,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
      ),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
}
