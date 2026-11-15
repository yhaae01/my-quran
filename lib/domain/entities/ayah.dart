import 'mushaf.dart';
import 'reciter.dart';

class Ayah {
  const Ayah({
    required this.surahNumber,
    required this.number,
    required this.arabic,
    required this.translation,
    this.uthmani,
    this.audioUrl,
    this.audioUrls = const {},
  });

  final int surahNumber;
  final int number;

  /// Arabic text in the Indonesian (Kemenag) rasm.
  final String arabic;

  /// Arabic text in the Madinah (Uthmani) rasm, when available.
  final String? uthmani;

  final String translation;

  /// Legacy single URL kept for caches written before reciter selection.
  final String? audioUrl;

  /// Per-ayah audio URLs keyed by [Reciter.id] (`01`..`06`).
  final Map<String, String> audioUrls;

  String get key => '$surahNumber:$number';

  /// The user's reciter URL when the cached API response has it, otherwise the
  /// deterministic CDN path so every reciter works with old cached data.
  String audioUrlFor(Reciter reciter) {
    final stored = audioUrls[reciter.id];
    if (stored != null && stored.trim().isNotEmpty) return stored;
    return reciter.audioUrlFor(surahNumber, number);
  }

  String arabicFor(MushafStyle style) {
    if (style == MushafStyle.madinah) {
      final madinah = uthmani?.trim();
      if (madinah != null && madinah.isNotEmpty) return madinah;
    }
    return arabic;
  }
}
