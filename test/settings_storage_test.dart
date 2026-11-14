import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_quran/data/repositories/settings_repository_impl.dart';
import 'package:my_quran/domain/entities/app_settings.dart';
import 'package:my_quran/domain/entities/mushaf.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('my_quran_settings_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('settings_test');
  });

  setUp(() async {
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('defaults to following the system theme', () {
    final repository = SettingsRepositoryImpl(box);

    final settings = repository.load();

    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.arabicFontSize, AppSettings.defaultArabicFontSize);
    expect(settings.mushafStyle, MushafStyle.kemenag);
  });

  test('persists the selected theme mode', () async {
    final repository = SettingsRepositoryImpl(box);

    await repository.save(
      const AppSettings(
        themeMode: AppThemeMode.dark,
        arabicFontSize: 34,
        mushafStyle: MushafStyle.madinah,
      ),
    );

    final reloaded = SettingsRepositoryImpl(box).load();
    expect(reloaded.themeMode, AppThemeMode.dark);
    expect(reloaded.arabicFontSize, 34);
    expect(reloaded.mushafStyle, MushafStyle.madinah);

    await repository.save(reloaded.copyWith(themeMode: AppThemeMode.light));

    expect(SettingsRepositoryImpl(box).load().themeMode, AppThemeMode.light);
  });

  test('unknown persisted theme values fall back to system', () {
    expect(AppThemeMode.fromName('sepia'), AppThemeMode.system);
    expect(AppThemeMode.fromName(null), AppThemeMode.system);
    expect(AppThemeMode.fromName('dark'), AppThemeMode.dark);
  });
}
