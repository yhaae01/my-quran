import '../../domain/entities/mushaf.dart';

/// Basmalah glyphs matching the selected rasm.
String basmalahFor(MushafStyle style) {
  return style == MushafStyle.madinah
      ? 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'
      : 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ';
}
