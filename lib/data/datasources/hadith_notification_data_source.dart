import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/hadith.dart';
import '../../domain/repositories/hadith_repository.dart';

/// Schedules and manages the daily 05:00 AM Hadith notification.
///
/// Every morning gets its own fixed notification slot starting at
/// [dailyId] (500), and slots are always cancelled before being scheduled
/// again. This keeps the schedule idempotent: opening the app repeatedly
/// replaces the same alarms instead of stacking duplicate 05:00 alarms.
class HadithNotificationDataSource {
  HadithNotificationDataSource([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Fixed ID of the next 05:00 AM Hadith notification. The following
  /// mornings use [dailyId] + 1 ... [dailyId] + [daysAhead] - 1.
  static const int dailyId = 500;
  static const int daysAhead = 7;

  /// IDs used by releases that scheduled a repeating alarm plus six
  /// one-shots. Those produced two notifications at 05:00 and are cleaned up
  /// so upgraded installs start from a clean slate.
  static const int _legacyIdBase = 5000;
  static const int _legacyIdCount = 10;

  tz.TZDateTime? _scheduledFor;

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
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedules the daily 05:00 AM notifications for the upcoming
  /// [daysAhead] mornings, assigning a randomly selected hadith from
  /// [hadiths] to each morning.
  ///
  /// The call is guarded: if the same 05:00 AM target is already scheduled
  /// (in this process or still pending in the OS), it returns without
  /// registering another alarm.
  Future<void> scheduleDailyHadiths({
    required List<Hadith> hadiths,
    String? timeZoneId,
    DateTime? fromDate,
    Random? random,
  }) async {
    if (kIsWeb || hadiths.isEmpty) return;
    await _ensureInitialized();

    final location = _resolveLocation(timeZoneId);
    final firstScheduled = nextInstanceOf5AM(location, fromDate);

    // Fast path: this process already scheduled this exact morning.
    if (_scheduledFor == firstScheduled) return;

    final ids = List<int>.generate(daysAhead, (index) => dailyId + index);

    // Slow path: the OS may still hold the rolling schedule from an earlier
    // app session. Only re-register when a slot is actually missing.
    if (await _hasAllPending(ids)) {
      _scheduledFor = firstScheduled;
      return;
    }

    final android = _android;
    final canScheduleExact = android == null
        ? false
        : await android.canScheduleExactNotifications();
    final mode = canScheduleExact == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final rng = random ?? Random();

    await _cancelLegacySchedules();
    for (var i = 0; i < daysAhead; i++) {
      final id = dailyId + i;
      final scheduledDate = firstScheduled.add(Duration(days: i));
      final hadith = getRandomHadithFromList(hadiths, rng);

      // Cancel the previous alarm with this ID right before scheduling so a
      // repeated call can never leave two alarms for the same morning.
      await _plugin.cancel(id: id);
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: scheduledDate,
        title: 'Hadis Hari Ini',
        body: hadith.translation,
        notificationDetails: _buildDetails(hadith),
        androidScheduleMode: mode,
        // Deliberately no `matchDateTimeComponents`: a repeating alarm would
        // fire alongside the next morning's one-shot notification, which was
        // the cause of the duplicate 05:00 AM alerts.
        payload: 'hadith:${hadith.book}:${hadith.number}',
      );
    }
    _scheduledFor = firstScheduled;
  }

  /// Cancels all scheduled Hadith notifications.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    for (var i = 0; i < daysAhead; i++) {
      await _plugin.cancel(id: dailyId + i);
    }
    await _cancelLegacySchedules();
    _scheduledFor = null;
  }

  Future<bool> _hasAllPending(List<int> ids) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final pendingIds = pending.map((request) => request.id).toSet();
      return ids.every(pendingIds.contains);
    } catch (_) {
      // Platforms without pending-request support simply reschedule; IDs and
      // the pre-schedule cancel keep that safe.
      return false;
    }
  }

  Future<void> _cancelLegacySchedules() async {
    for (var id = _legacyIdBase; id < _legacyIdBase + _legacyIdCount; id++) {
      await _plugin.cancel(id: id);
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
    // Channel appearance (including its small icon) is cached by Android after
    // creation, so drop any channel created by an older release.
    try {
      await _android?.deleteNotificationChannel(channelId: 'daily_hadith');
    } catch (_) {
      // Channel may not exist yet.
    }
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
    final rawi = hadith.rawi;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_hadith_v2',
        'Hadis Hari Ini',
        channelDescription:
            'Notifikasi hadis pilihan setiap hari pukul 05:00 pagi',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        playSound: true,
        icon: 'ic_stat_logo',
        styleInformation: BigTextStyleInformation(
          hadith.translation,
          contentTitle: 'Hadis Hari Ini',
          summaryText: rawi == null || rawi.isEmpty
              ? hadith.reference
              : '${hadith.reference} • $rawi',
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
