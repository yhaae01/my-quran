import 'mushaf.dart';
import 'prayer_preferences.dart';

enum AppThemeMode {
  system,
  light,
  dark;

  String get label => switch (this) {
    AppThemeMode.system => 'Sistem',
    AppThemeMode.light => 'Terang',
    AppThemeMode.dark => 'Gelap',
  };

  static AppThemeMode fromName(String? name) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => AppThemeMode.system,
    );
  }
}

class AppSettings {
  const AppSettings({
    this.arabicFontSize = defaultArabicFontSize,
    this.showTranslation = true,
    this.mushafStyle = MushafStyle.kemenag,
    this.themeMode = AppThemeMode.system,
    this.prayer = const PrayerPreferences(),
  });

  static const double minArabicFontSize = 20;
  static const double maxArabicFontSize = 48;
  static const double defaultArabicFontSize = 28;

  final double arabicFontSize;

  /// When false the ayah-by-ayah reader shows clean Arabic text only.
  final bool showTranslation;
  final MushafStyle mushafStyle;
  final AppThemeMode themeMode;
  final PrayerPreferences prayer;

  AppSettings copyWith({
    double? arabicFontSize,
    bool? showTranslation,
    MushafStyle? mushafStyle,
    AppThemeMode? themeMode,
    PrayerPreferences? prayer,
  }) {
    return AppSettings(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      showTranslation: showTranslation ?? this.showTranslation,
      mushafStyle: mushafStyle ?? this.mushafStyle,
      themeMode: themeMode ?? this.themeMode,
      prayer: prayer ?? this.prayer,
    );
  }
}
