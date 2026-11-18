import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/daily_tilawah_local_data_source.dart';
import '../../domain/entities/daily_tilawah.dart';
import '../../domain/entities/reading_progress.dart';
import 'auth_providers.dart';
import 'core_providers.dart';
import 'reading_progress_providers.dart';

final Provider<DailyTilawahLocalDataSource>
dailyTilawahLocalDataSourceProvider = Provider<DailyTilawahLocalDataSource>(
  (ref) => DailyTilawahLocalDataSource(ref.watch(settingsBoxProvider)),
);

/// Owns today's 1D1J target, credits progress from the live reading position,
/// resets itself at midnight, and mirrors completion to reading groups.
class DailyTilawahNotifier extends Notifier<DailyTilawah> {
  Timer? _midnightTimer;
  bool _disposed = false;

  DailyTilawahLocalDataSource get _store =>
      ref.read(dailyTilawahLocalDataSourceProvider);

  @override
  DailyTilawah build() {
    final progress = ref.read(readingProgressProvider);
    final today = DailyTilawah.today();
    final stored = _store.read();
    final startsToday = stored != null && stored.isForDay(today);

    var daily = startsToday
        ? stored
        : DailyTilawah.startingAt(
            baselineVerse: progress?.versesRead ?? 0,
            date: today,
          );
    if (!daily.completed && daily.isCompleteFor(progress)) {
      daily = daily.copyWith(completed: true, completedAt: DateTime.now());
    }
    if (!startsToday || daily != stored) {
      unawaited(_store.write(daily));
    }

    ref.onDispose(() {
      _disposed = true;
      _midnightTimer?.cancel();
    });
    _scheduleMidnightReset();
    ref.listen<ReadingProgress?>(readingProgressProvider, (previous, next) {
      unawaited(_autoComplete(next));
    });

    return daily;
  }

  /// Credits one page the reader read outside the app.
  Future<void> addManualPage() async {
    final progress = ref.read(readingProgressProvider);
    if (state.pagesRead(progress) >= state.targetPages) return;
    state = state.copyWith(manualPages: state.manualPages + 1);
    await _store.write(state);
    if (state.isCompleteFor(progress)) {
      await markCompleted();
    }
  }

  /// Marks the target done and immediately updates every joined group.
  Future<void> markCompleted() async {
    if (!state.completed) {
      state = state.copyWith(completed: true, completedAt: DateTime.now());
      await _store.write(state);
    }
    await syncToGroups();
  }

  /// Pushes today's target (pages + completion) to the reading challenge
  /// leaderboard, alongside the current reading position.
  Future<void> syncToGroups() async {
    final progress = ref.read(readingProgressProvider);
    if (progress == null) return;
    if (!ref.read(firebaseReadyProvider)) return;
    if (ref.read(currentUserProvider) == null) return;
    await ref.read(syncReadingProgressProvider)(progress, daily: state);
  }

  Future<void> _autoComplete(ReadingProgress? progress) async {
    if (_disposed || state.completed) return;
    if (!state.isCompleteFor(progress)) return;
    state = state.copyWith(completed: true, completedAt: DateTime.now());
    await _store.write(state);
    try {
      await syncToGroups();
    } catch (_) {
      // The completion stays local; the next sync retries it.
    }
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () {
        if (_disposed) return;
        unawaited(_startNewDay());
        _scheduleMidnightReset();
      },
    );
  }

  Future<void> _startNewDay() async {
    final progress = ref.read(readingProgressProvider);
    final daily = DailyTilawah.startingAt(
      baselineVerse: progress?.versesRead ?? 0,
    );
    state = daily;
    await _store.write(daily);
  }
}

final NotifierProvider<DailyTilawahNotifier, DailyTilawah>
dailyTilawahProvider = NotifierProvider<DailyTilawahNotifier, DailyTilawah>(
  DailyTilawahNotifier.new,
);
