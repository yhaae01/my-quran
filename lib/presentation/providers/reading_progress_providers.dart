import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_progress.dart';
import 'auth_providers.dart';
import 'bookmark_providers.dart';
import 'core_providers.dart';

/// Furthest position reached on this device. Kept locally and mirrored to every
/// reading group the signed-in reader has joined.
///
/// This is the only source of challenge progress: personal bookmarks live in
/// their own Hive box and never write here, so saving, editing or deleting a
/// bookmark cannot change the real-time leaderboard. Opening a bookmark also
/// skips the initial auto-jump report (see `SurahReaderPage.reportInitialAyah`).
/// The one exception is the explicit "Jadikan Lanjutkan Bacaan" action, which
/// calls [setPosition] to make the chosen primary bookmark the shared position.
class ReadingProgressNotifier extends Notifier<ReadingProgress?> {
  Timer? _syncTimer;
  ReadingProgress? _pending;

  static const Duration _syncDelay = Duration(seconds: 2);

  @override
  ReadingProgress? build() {
    ref.onDispose(() => _syncTimer?.cancel());
    return ref.watch(loadReadingProgressProvider)();
  }

  Future<void> record({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
  }) async {
    final next = ReadingProgress(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      updatedAt: DateTime.now(),
    );
    final current = state;
    if (current != null && next.versesRead <= current.versesRead) return;

    state = next;
    await ref.read(saveReadingProgressProvider)(next);
    _scheduleSync(next);

    // Actual reading has moved past the pinned bookmark, so the latest active
    // position becomes the single "Lanjutkan Bacaan" reference again.
    final pinned = ref.read(continueReadingBookmarkProvider);
    if (pinned != null &&
        next.versesRead >
            cumulativeVerseNumber(pinned.surahNumber, pinned.verseNumber)) {
      await ref.read(bookmarksProvider.notifier).clearContinueReading();
    }
  }

  /// Moves the shared position to an explicitly chosen verse, even when it is
  /// behind the current progress. Used by "Jadikan Lanjutkan Bacaan", whose
  /// position must be the one mirrored to every reading group.
  Future<void> setPosition({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
  }) async {
    final next = ReadingProgress(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      updatedAt: DateTime.now(),
    );
    state = next;
    await ref.read(saveReadingProgressProvider)(next);
    _scheduleSync(next);
  }

  void _scheduleSync(ReadingProgress next) {
    _pending = next;
    _syncTimer?.cancel();
    _syncTimer = Timer(_syncDelay, () => unawaited(_flush()));
  }

  /// Pushes the current position immediately; errors reach the caller so the
  /// UI can show what went wrong.
  Future<void> syncNow() async {
    final progress = state;
    if (progress == null) return;
    _syncTimer?.cancel();
    _pending = null;
    await ref.read(syncReadingProgressProvider)(progress);
  }

  Future<void> _flush() async {
    final pending = _pending;
    _pending = null;
    if (pending == null) return;
    if (!ref.read(firebaseReadyProvider)) return;
    if (ref.read(currentUserProvider) == null) return;
    try {
      await ref.read(syncReadingProgressProvider)(pending);
    } catch (_) {
      // Offline or signed out mid-write: the local position stays authoritative
      // and is retried on the next page or through the manual sync button.
    }
  }
}

final NotifierProvider<ReadingProgressNotifier, ReadingProgress?>
readingProgressProvider =
    NotifierProvider<ReadingProgressNotifier, ReadingProgress?>(
      ReadingProgressNotifier.new,
    );
