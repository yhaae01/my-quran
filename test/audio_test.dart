import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/core/utils/audio_timing.dart';
import 'package:my_quran/data/models/surah_models.dart';
import 'package:my_quran/domain/entities/ayah.dart';
import 'package:my_quran/domain/entities/reciter.dart';

void main() {
  group('Reciter', () {
    test('exposes the six equran partial-audio voices', () {
      expect(Reciter.all, hasLength(6));
      expect(Reciter.all.map((item) => item.id).toSet(), {
        '01',
        '02',
        '03',
        '04',
        '05',
        '06',
      });
    });

    test('falls back to Mishary for an unknown or missing id', () {
      expect(Reciter.fromId(null), Reciter.misharyAlafasy);
      expect(Reciter.fromId('99'), Reciter.misharyAlafasy);
      expect(Reciter.fromId('03'), Reciter.abdurrahmanAsSudais);
    });

    test('builds a padded CDN url for any ayah', () {
      expect(
        Reciter.misharyAlafasy.audioUrlFor(2, 255),
        'https://cdn.equran.id/audio-partial/Misyari-Rasyid-Al-Afasi/002255.mp3',
      );
    });
  });

  group('Ayah audio urls', () {
    test('prefers the cached per-reciter url and then the CDN fallback', () {
      const ayah = Ayah(
        surahNumber: 1,
        number: 1,
        arabic: 'بِسْمِ اللّٰهِ',
        translation: 'Dengan nama Allah',
        audioUrls: {'05': 'https://example.test/05/1/1.mp3'},
      );

      expect(
        ayah.audioUrlFor(Reciter.misharyAlafasy),
        'https://example.test/05/1/1.mp3',
      );
      expect(
        ayah.audioUrlFor(Reciter.abdurrahmanAsSudais),
        'https://cdn.equran.id/audio-partial/Abdurrahman-as-Sudais/001001.mp3',
      );
    });

    test('parser keeps every audio map entry through a cache round trip', () {
      final model = AyahModel.fromEquran({
        'nomorAyat': 7,
        'teksArab': 'text',
        'teksIndonesia': 'translation',
        'audio': {
          '01': 'https://cdn.test/01.mp3',
          '03': 'https://cdn.test/03.mp3',
          '05': 'https://cdn.test/05.mp3',
        },
      });

      expect(model.audioUrls, hasLength(3));
      final restored = AyahModel.fromJson(model.toJson());
      expect(restored.audioUrls, model.audioUrls);
      expect(restored.audioUrl, model.audioUrl);
      expect(
        restored.toEntity(1).audioUrlFor(Reciter.abdurrahmanAsSudais),
        'https://cdn.test/03.mp3',
      );
    });
  });

  group('activeWordIndex', () {
    final words = ['بسم', 'الله', 'الرحمن', 'الرحيم'];
    const duration = Duration(seconds: 10);

    test('returns null before playback or without a duration', () {
      expect(
        activeWordIndex(
          words: words,
          position: Duration.zero,
          duration: duration,
        ),
        isNull,
      );
      expect(
        activeWordIndex(
          words: words,
          position: const Duration(seconds: 2),
          duration: Duration.zero,
        ),
        isNull,
      );
      expect(
        activeWordIndex(
          words: const [],
          position: const Duration(seconds: 2),
          duration: duration,
        ),
        isNull,
      );
    });

    test('advances through words as the position grows', () {
      final first = activeWordIndex(
        words: words,
        position: const Duration(seconds: 1),
        duration: duration,
      );
      final middle = activeWordIndex(
        words: words,
        position: const Duration(seconds: 5),
        duration: duration,
      );
      final last = activeWordIndex(
        words: words,
        position: const Duration(milliseconds: 9900),
        duration: duration,
      );

      expect(first, 0);
      expect(middle, greaterThan(first!));
      expect(last, words.length - 1);
    });
  });
}
