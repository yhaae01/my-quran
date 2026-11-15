import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah.dart';
import 'audio_download_provider.dart';

class AudioTrack {
  const AudioTrack({
    required this.url,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    this.localPath,
  });

  final String url;

  /// Set when the ayah has been downloaded and can play without a network.
  final String? localPath;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;

  Uri get uri {
    final path = localPath;
    if (path != null && path.isNotEmpty) return Uri.file(path);
    return Uri.parse(url);
  }
}

class AudioPlaybackState {
  const AudioPlaybackState({
    this.tracks = const [],
    this.currentIndex,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
    this.reciterId,
  });

  /// The whole surah is queued, so just_audio can advance to the next ayah on
  /// its own and the reader can highlight the active one.
  final List<AudioTrack> tracks;
  final int? currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final String? error;
  final String? reciterId;

  AudioTrack? get currentTrack {
    final index = currentIndex;
    if (index == null || index < 0 || index >= tracks.length) return null;
    return tracks[index];
  }

  int? get surahNumber => currentTrack?.surahNumber;
  int? get ayahNumber => currentTrack?.ayahNumber;

  bool get hasTrack => currentTrack != null;

  AudioPlaybackState copyWith({
    List<AudioTrack>? tracks,
    int? currentIndex,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    String? error,
    bool clearError = false,
    String? reciterId,
  }) {
    return AudioPlaybackState(
      tracks: tracks ?? this.tracks,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
      reciterId: reciterId ?? this.reciterId,
    );
  }
}

class AyahAudioNotifier extends Notifier<AudioPlaybackState> {
  late AudioPlayer _player;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  @override
  AudioPlaybackState build() {
    _disposed = false;
    _player = AudioPlayer();

    _subscriptions.add(
      _player.currentIndexStream.listen((index) {
        if (_disposed || index == null || state.tracks.isEmpty) return;
        state = state.copyWith(
          currentIndex: index,
          position: Duration.zero,
          duration: Duration.zero,
          isLoading: true,
          clearError: true,
        );
      }),
    );
    _subscriptions.add(
      _player.positionStream.listen((position) {
        if (_disposed) return;
        state = state.copyWith(position: position);
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (_disposed || duration == null) return;
        state = state.copyWith(duration: duration);
      }),
    );
    _subscriptions.add(
      _player.playingStream.listen((playing) {
        if (_disposed) return;
        state = state.copyWith(isPlaying: playing);
      }),
    );
    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        if (_disposed) return;
        state = switch (playerState.processingState) {
          ProcessingState.completed => state.copyWith(
            isPlaying: false,
            isLoading: false,
          ),
          ProcessingState.loading ||
          ProcessingState.buffering => state.copyWith(isLoading: true),
          ProcessingState.ready ||
          ProcessingState.idle => state.copyWith(isLoading: false),
        };
      }),
    );

    ref.onDispose(() {
      _disposed = true;
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      unawaited(_player.dispose());
    });
    return const AudioPlaybackState();
  }

  /// Starts (or resumes/pauses) the surah queue at one ayah.
  ///
  /// The entire surah is handed to just_audio as a playlist, so when an ayah
  /// finishes the next one starts automatically and [currentIndex] drives the
  /// active-ayah highlight.
  Future<void> toggleAyah({
    required SurahDetail detail,
    required int ayahIndex,
    required Reciter reciter,
  }) async {
    if (detail.ayahs.isEmpty) return;
    final safeIndex = ayahIndex.clamp(0, detail.ayahs.length - 1);

    final isSameAyah =
        state.reciterId == reciter.id &&
        state.surahNumber == detail.surah.number &&
        state.currentIndex == safeIndex;

    if (isSameAyah) {
      if (_player.playing) {
        await _player.pause();
      } else {
        unawaited(_resumePlayback());
      }
      return;
    }

    final isSameQueue =
        state.reciterId == reciter.id &&
        state.surahNumber == detail.surah.number &&
        state.tracks.length == detail.ayahs.length;

    if (isSameQueue) {
      state = state.copyWith(
        currentIndex: safeIndex,
        position: Duration.zero,
        duration: Duration.zero,
        isLoading: true,
        clearError: true,
      );
      try {
        await _player.seek(Duration.zero, index: safeIndex);
        unawaited(_resumePlayback());
      } catch (_) {
        await _startQueue(detail, safeIndex, reciter);
      }
      return;
    }

    await _startQueue(detail, safeIndex, reciter);
  }

  Future<void> _startQueue(
    SurahDetail detail,
    int startIndex,
    Reciter reciter,
  ) async {
    AudioDownloadState downloads;
    try {
      downloads = await ref.read(audioDownloadsProvider.future);
    } catch (_) {
      downloads = const AudioDownloadState();
    }
    if (_disposed) return;

    final tracks = <AudioTrack>[
      for (final ayah in detail.ayahs)
        AudioTrack(
          url: ayah.audioUrlFor(reciter),
          localPath: downloads.pathFor(
            reciter.id,
            detail.surah.number,
            ayah.number,
          ),
          surahNumber: detail.surah.number,
          ayahNumber: ayah.number,
          surahName: detail.surah.latinName,
        ),
    ];

    state = AudioPlaybackState(
      tracks: tracks,
      currentIndex: startIndex,
      isLoading: true,
      reciterId: reciter.id,
      duration: Duration.zero,
      position: Duration.zero,
    );

    try {
      await _player.setAudioSources([
        for (final track in tracks) AudioSource.uri(track.uri),
      ], initialIndex: startIndex);
      if (_disposed) return;
      unawaited(_resumePlayback());
    } on PlayerInterruptedException {
      // A newer tap replaced this queue; the newer call owns the state.
    } catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        error: 'Audio ayat tidak dapat diputar. Periksa koneksi internet.',
      );
    }
  }

  Future<void> _resumePlayback() async {
    try {
      await _player.play();
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        error: 'Audio ayat tidak dapat diputar. Periksa koneksi internet.',
      );
    }
  }

  Future<void> stop() async {
    await _player.stop();
    if (_disposed) return;
    state = const AudioPlaybackState();
  }
}

final NotifierProvider<AyahAudioNotifier, AudioPlaybackState>
ayahAudioProvider = NotifierProvider<AyahAudioNotifier, AudioPlaybackState>(
  AyahAudioNotifier.new,
);
