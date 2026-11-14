import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/core/theme/app_theme.dart';
import 'package:my_quran/domain/entities/app_settings.dart';
import 'package:my_quran/domain/repositories/settings_repository.dart';
import 'package:my_quran/presentation/pages/settings_page.dart';
import 'package:my_quran/presentation/providers/core_providers.dart';
import 'package:my_quran/presentation/providers/settings_providers.dart';

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings();

  @override
  AppSettings load() => settings;

  @override
  Future<void> save(AppSettings next) async {
    settings = next;
  }
}

ThemeMode _toThemeMode(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}

void main() {
  testWidgets('theme selector switches MaterialApp to dark and persists it', (
    tester,
  ) async {
    final repository = _FakeSettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
        child: Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(
              settingsProvider.select((settings) => settings.themeMode),
            );
            return MaterialApp(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: _toThemeMode(mode),
              home: const SettingsPage(),
            );
          },
        ),
      ),
    );

    expect(repository.settings.themeMode, AppThemeMode.system);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();

    expect(repository.settings.themeMode, AppThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Terang'));
    await tester.pumpAndSettle();

    expect(repository.settings.themeMode, AppThemeMode.light);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.light,
    );
  });
}
