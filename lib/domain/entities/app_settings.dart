import 'mushaf.dart';
import 'prayer_preferences.dart';
import 'reciter.dart';

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
    this.reciterId = '05',
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

  /// Chosen murottal reciter (`Reciter.id`).
  final String reciterId;

  Reciter get reciter => Reciter.fromId(reciterId);

  AppSettings copyWith({
    double? arabicFontSize,
    bool? showTranslation,
    MushafStyle? mushafStyle,
    AppThemeMode? themeMode,
    PrayerPreferences? prayer,
    String? reciterId,
  }) {
    return AppSettings(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      showTranslation: showTranslation ?? this.showTranslation,
      mushafStyle: mushafStyle ?? this.mushafStyle,
      themeMode: themeMode ?? this.themeMode,
      prayer: prayer ?? this.prayer,
      reciterId: reciterId ?? this.reciterId,
    );
  }
}
