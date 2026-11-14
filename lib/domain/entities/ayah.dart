import 'mushaf.dart';

class Ayah {
  const Ayah({
    required this.surahNumber,
    required this.number,
    required this.arabic,
    required this.translation,
    this.uthmani,
    this.audioUrl,
  });

  final int surahNumber;
  final int number;

  /// Arabic text in the Indonesian (Kemenag) rasm.
  final String arabic;

  /// Arabic text in the Madinah (Uthmani) rasm, when available.
  final String? uthmani;

  final String translation;
  final String? audioUrl;

  String get key => '$surahNumber:$number';

  String arabicFor(MushafStyle style) {
    if (style == MushafStyle.madinah) {
      final madinah = uthmani?.trim();
      if (madinah != null && madinah.isNotEmpty) return madinah;
    }
    return arabic;
  }
}
