import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlaybackState {
  const AudioPlaybackState({
    this.url,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
  });

  final String? url;
  final bool isPlaying;
  final bool isLoading;
  final String? error;

  AudioPlaybackState copyWith({
    String? url,
    bool? isPlaying,
    bool? isLoading,
    String? error,
  }) {
    return AudioPlaybackState(
      url: url ?? this.url,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AyahAudioNotifier extends Notifier<AudioPlaybackState> {
  late AudioPlayer _player;
  StreamSubscription<PlayerState>? _subscription;
  bool _disposed = false;

  @override
  AudioPlaybackState build() {
    _disposed = false;
    _player = AudioPlayer();
    _subscription = _player.playerStateStream.listen((playerState) {
      if (!_disposed &&
          playerState.processingState == ProcessingState.completed) {
        state = const AudioPlaybackState();
      }
    });
    ref.onDispose(() {
      _disposed = true;
      unawaited(_subscription?.cancel() ?? Future<void>.value());
      unawaited(_player.dispose());
    });
    return const AudioPlaybackState();
  }

  Future<void> toggle(String url) async {
    try {
      if (state.url == url) {
        if (state.isPlaying) {
          await _player.pause();
          if (_disposed) return;
          state = state.copyWith(isPlaying: false);
        } else {
          unawaited(_player.play());
          if (_disposed) return;
          state = state.copyWith(isPlaying: true, error: null);
        }
        return;
      }

      state = AudioPlaybackState(url: url, isLoading: true);
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      if (_disposed) return;
      unawaited(_player.play());
      state = AudioPlaybackState(url: url, isPlaying: true);
    } catch (_) {
      if (_disposed) return;
      state = AudioPlaybackState(
        url: url,
        error: 'Audio ayat tidak dapat diputar.',
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
