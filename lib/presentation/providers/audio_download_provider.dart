import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../data/repositories/audio_download_repository.dart';
import '../../domain/entities/reciter.dart';
import 'core_providers.dart';

class AudioDownloadState {
  const AudioDownloadState({
    this.paths = const {},
    this.progress = const {},
    this.error,
  });

  /// `reciter:surah:ayah` -> absolute file path.
  final Map<String, String> paths;

  /// `reciter:surah` -> 0..1 while a surah download is running.
  final Map<String, double> progress;
  final String? error;

  String? pathFor(String reciterId, int surahNumber, int ayahNumber) {
    return paths[AudioDownloadRepository.keyFor(
      reciterId,
      surahNumber,
      ayahNumber,
    )];
  }

  double? progressFor(String reciterId, int surahNumber) {
    return progress['$reciterId:$surahNumber'];
  }

  bool isSurahDownloaded(String reciterId, int surahNumber, int ayahCount) {
    if (ayahCount <= 0) return false;
    for (var ayah = 1; ayah <= ayahCount; ayah++) {
      if (pathFor(reciterId, surahNumber, ayah) == null) return false;
    }
    return true;
  }

  AudioDownloadState copyWith({
    Map<String, String>? paths,
    Map<String, double>? progress,
    String? error,
    bool clearError = false,
  }) {
    return AudioDownloadState(
      paths: paths ?? this.paths,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AudioDownloadNotifier extends AsyncNotifier<AudioDownloadState> {
  bool _disposed = false;

  @override
  Future<AudioDownloadState> build() async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final paths = await ref.read(audioDownloadRepositoryProvider).load();
    return AudioDownloadState(paths: paths);
  }

  Future<void> downloadSurah({
    required Reciter reciter,
    required int surahNumber,
    required List<String> audioUrls,
  }) async {
    if (audioUrls.isEmpty) return;
    final current = state.value ?? const AudioDownloadState();
    final surahKey = '${reciter.id}:$surahNumber';
    if (current.progress.containsKey(surahKey)) return;

    state = AsyncValue.data(
      current.copyWith(
        progress: {...current.progress, surahKey: 0},
        clearError: true,
      ),
    );

    try {
      final paths = await ref
          .read(audioDownloadRepositoryProvider)
          .downloadSurah(
            reciter: reciter,
            surahNumber: surahNumber,
            audioUrls: audioUrls,
            onProgress: (completed, total) {
              if (_disposed) return;
              final latest = state.value ?? const AudioDownloadState();
              state = AsyncValue.data(
                latest.copyWith(
                  progress: {
                    ...latest.progress,
                    surahKey: total == 0 ? 0 : completed / total,
                  },
                ),
              );
            },
          );
      if (_disposed) return;
      final latest = state.value ?? current;
      final progress = {...latest.progress}..remove(surahKey);
      state = AsyncValue.data(
        AudioDownloadState(paths: paths, progress: progress),
      );
    } catch (error) {
      if (_disposed) return;
      final latest = state.value ?? current;
      final progress = {...latest.progress}..remove(surahKey);
      state = AsyncValue.data(
        latest.copyWith(
          progress: progress,
          error: error is Failure ? error.message : 'Unduhan audio gagal diselesaikan. Periksa koneksi lalu coba lagi.',
        ),
      );
    }
  }

  Future<void> deleteSurah({
    required Reciter reciter,
    required int surahNumber,
  }) async {
    final current = state.value;
    if (current == null) return;
    final prefix = '${reciter.id}:$surahNumber:';
    final paths = {
      for (final entry in current.paths.entries)
        if (!entry.key.startsWith(prefix)) entry.key: entry.value,
    };
    state = AsyncValue.data(current.copyWith(paths: paths, clearError: true));
    try {
      await ref
          .read(audioDownloadRepositoryProvider)
          .deleteSurah(reciter: reciter, surahNumber: surahNumber);
    } catch (_) {
      // The files may already be gone; the index above is still correct.
    }
  }
}

final AsyncNotifierProvider<AudioDownloadNotifier, AudioDownloadState>
audioDownloadsProvider =
    AsyncNotifierProvider<AudioDownloadNotifier, AudioDownloadState>(
      AudioDownloadNotifier.new,
    );
