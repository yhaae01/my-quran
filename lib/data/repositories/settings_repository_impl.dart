import 'package:hive/hive.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/mushaf.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._box);

  final Box<dynamic> _box;

  static const String _fontSizeKey = 'arabic_font_size';
  static const String _mushafStyleKey = 'mushaf_style';
  static const String _themeModeKey = 'theme_mode';

  @override
  AppSettings load() {
    final storedSize = _box.get(_fontSizeKey);
    final storedStyle = _box.get(_mushafStyleKey);
    final storedThemeMode = _box.get(_themeModeKey);

    final fontSize = storedSize is num
        ? storedSize
              .toDouble()
              .clamp(
                AppSettings.minArabicFontSize,
                AppSettings.maxArabicFontSize,
              )
              .toDouble()
        : AppSettings.defaultArabicFontSize;

    return AppSettings(
      arabicFontSize: fontSize,
      mushafStyle: storedStyle is String
          ? MushafStyle.fromId(storedStyle)
          : MushafStyle.kemenag,
      themeMode: AppThemeMode.fromName(
        storedThemeMode is String ? storedThemeMode : null,
      ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _box.put(_fontSizeKey, settings.arabicFontSize);
    await _box.put(_mushafStyleKey, settings.mushafStyle.id);
    await _box.put(_themeModeKey, settings.themeMode.name);
  }
}
