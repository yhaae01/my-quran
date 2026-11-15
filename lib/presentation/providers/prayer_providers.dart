import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_preferences.dart';
import 'core_providers.dart';
import 'settings_providers.dart';

/// Ticks once a second while a prayer screen or widget preview is visible.
final StreamProvider<DateTime> prayerClockProvider = StreamProvider<DateTime>((
  ref,
) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

final FutureProvider<bool> prayerWidgetPinSupportedProvider = FutureProvider(
  (ref) => ref.watch(syncPrayerWidgetProvider).canPin(),
);

/// Loads the weekly schedule and keeps notifications plus the home screen
/// widget in sync. Explicit `refresh()` calls make the side effects predictable
/// and avoid double scheduling when several screens rebuild.
class PrayerSyncNotifier extends AsyncNotifier<PrayerSchedule?> {
  @override
  Future<PrayerSchedule?> build() async => null;

  Future<void> refresh({bool showLoading = true}) async {
    final preferences = ref.read(settingsProvider).prayer;
    if (showLoading) state = const AsyncValue.loading();
    try {
      final schedule = ref.read(getPrayerScheduleProvider)(preferences);
      await _syncSideEffects(schedule, preferences);
      state = AsyncValue.data(schedule);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _syncSideEffects(
    PrayerSchedule schedule,
    PrayerPreferences preferences,
  ) async {
    try {
      await ref.read(syncPrayerRemindersProvider)(schedule, preferences);
    } catch (error) {
      debugPrint('Pengingat shalat tidak tersinkron: $error');
    }
    try {
      await ref.read(syncPrayerWidgetProvider)(schedule, preferences);
    } catch (error) {
      debugPrint('Widget shalat tidak tersinkron: $error');
    }
    try {
      await ref.read(scheduleDailyHadithNotificationProvider)(
        timeZoneId: schedule.timeZoneId,
      );
    } catch (error) {
      debugPrint('Notifikasi hadis harian tidak tersinkron: $error');
    }
  }
}

final AsyncNotifierProvider<PrayerSyncNotifier, PrayerSchedule?>
prayerSyncProvider = AsyncNotifierProvider<PrayerSyncNotifier, PrayerSchedule?>(
  PrayerSyncNotifier.new,
);

/// Re-syncs reminders and widget whenever the prayer preferences change.
final Provider<void> prayerSettingsSyncProvider = Provider<void>((ref) {
  ref.listen(settingsProvider.select((settings) => settings.prayer), (
    previous,
    next,
  ) {
    if (previous == next) return;
    unawaited(
      ref.read(prayerSyncProvider.notifier).refresh(showLoading: false),
    );
  });
});
