import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/mushaf.dart';
import 'core_providers.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return ref.watch(settingsRepositoryProvider).load();
  }

  void setArabicFontSize(double size) {
    final clamped = size
        .clamp(AppSettings.minArabicFontSize, AppSettings.maxArabicFontSize)
        .toDouble();
    if (clamped == state.arabicFontSize) return;
    _update(state.copyWith(arabicFontSize: clamped));
  }

  void setMushafStyle(MushafStyle style) {
    if (style == state.mushafStyle) return;
    _update(state.copyWith(mushafStyle: style));
  }

  void setThemeMode(AppThemeMode mode) {
    if (mode == state.themeMode) return;
    _update(state.copyWith(themeMode: mode));
  }

  void _update(AppSettings next) {
    state = next;
    unawaited(ref.read(settingsRepositoryProvider).save(next));
  }
}

final NotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
