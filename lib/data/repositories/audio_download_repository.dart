import '../datasources/audio_file_store.dart';
import '../../domain/entities/reciter.dart';

/// Downloads and indexes per-ayah murottal files for offline playback.
class AudioDownloadRepository {
  AudioDownloadRepository({AudioFileStore? store})
    : _store = store ?? AudioFileStore();

  final AudioFileStore _store;

  static String keyFor(String reciterId, int surahNumber, int ayahNumber) {
    return '$reciterId:$surahNumber:$ayahNumber';
  }

  static String _surahFolder(String reciterId, int surahNumber) {
    return '$reciterId/${surahNumber.toString().padLeft(3, '0')}';
  }

  static String _relativePath(
    String reciterId,
    int surahNumber,
    int ayahNumber,
  ) {
    final ayah = ayahNumber.toString().padLeft(3, '0');
    return '${_surahFolder(reciterId, surahNumber)}/$ayah.mp3';
  }

  Future<Map<String, String>> load() => _store.scan();

  /// Downloads every missing ayah of one surah sequentially. Returns the fresh
  /// index so the caller can serve the files immediately.
  Future<Map<String, String>> downloadSurah({
    required Reciter reciter,
    required int surahNumber,
    required List<String> audioUrls,
    void Function(int completed, int total)? onProgress,
  }) async {
    final existing = await _store.scan();
    final total = audioUrls.length;

    for (var index = 0; index < audioUrls.length; index++) {
      final ayahNumber = index + 1;
      final key = keyFor(reciter.id, surahNumber, ayahNumber);
      if (!existing.containsKey(key)) {
        await _store.download(
          url: audioUrls[index],
          relativePath: _relativePath(reciter.id, surahNumber, ayahNumber),
        );
      }
      onProgress?.call(index + 1, total);
    }

    return _store.scan();
  }

  Future<void> deleteSurah({
    required Reciter reciter,
    required int surahNumber,
  }) {
    return _store.deleteDirectory(_surahFolder(reciter.id, surahNumber));
  }
}
