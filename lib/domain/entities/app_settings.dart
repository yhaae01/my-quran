import 'mushaf.dart';

class AppSettings {
  const AppSettings({
    this.arabicFontSize = defaultArabicFontSize,
    this.mushafStyle = MushafStyle.kemenag,
  });

  static const double minArabicFontSize = 20;
  static const double maxArabicFontSize = 48;
  static const double defaultArabicFontSize = 28;

  final double arabicFontSize;
  final MushafStyle mushafStyle;

  AppSettings copyWith({double? arabicFontSize, MushafStyle? mushafStyle}) {
    return AppSettings(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      mushafStyle: mushafStyle ?? this.mushafStyle,
    );
  }
}
