import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/domain/entities/mushaf.dart';

void main() {
  const index = MushafPageIndex(
    style: MushafStyle.madinah,
    starts: [
      PageStart(surah: 1, ayah: 1, juz: 1),
      PageStart(surah: 2, ayah: 1, juz: 1),
      PageStart(surah: 2, ayah: 6, juz: 1),
    ],
  );

  group('MushafPageIndex', () {
    test('resolves the page that contains a verse', () {
      expect(index.pageOf(1, 7), 1);
      expect(index.pageOf(2, 1), 2);
      expect(index.pageOf(2, 5), 2);
      expect(index.pageOf(2, 6), 3);
      expect(index.pageOf(2, 255), 3);
    });

    test('builds a start-inclusive end-exclusive page range', () {
      final range = index.rangeOf(2);

      expect(range.contains(1, 7), isFalse);
      expect(range.contains(2, 1), isTrue);
      expect(range.contains(2, 5), isTrue);
      expect(range.contains(2, 6), isFalse);
      expect(range.lastSurahNumber, 2);
    });

    test('last page has no upper boundary', () {
      final range = index.rangeOf(3);

      expect(range.contains(2, 6), isTrue);
      expect(range.contains(3, 1), isTrue);
      expect(range.contains(114, 6), isTrue);
      expect(range.lastSurahNumber, 114);
    });

    test('excludes a surah that only starts after the page ends', () {
      const boundaryIndex = MushafPageIndex(
        style: MushafStyle.kemenag,
        starts: [
          PageStart(surah: 1, ayah: 1, juz: 1),
          PageStart(surah: 2, ayah: 1, juz: 1),
          PageStart(surah: 2, ayah: 6, juz: 1),
        ],
      );
      final pageOne = boundaryIndex.rangeOf(1);

      expect(pageOne.lastSurahNumber, 1);
      expect(boundaryIndex.startOf(1).juz, 1);
    });

    test('resolves the juz that contains a verse', () {
      const juzIndex = MushafPageIndex(
        style: MushafStyle.madinah,
        starts: [
          PageStart(surah: 1, ayah: 1, juz: 1),
          PageStart(surah: 2, ayah: 1, juz: 1),
          PageStart(surah: 2, ayah: 142, juz: 2),
          PageStart(surah: 2, ayah: 253, juz: 3),
        ],
      );

      expect(juzIndex.juzForVerse(1, 7), 1);
      expect(juzIndex.juzForVerse(2, 141), 1);
      expect(juzIndex.juzForVerse(2, 142), 2);
      expect(juzIndex.juzForVerse(2, 252), 2);
      expect(juzIndex.juzForVerse(2, 253), 3);
    });

    test('parses a style from the bundled asset shape', () {
      final parsed = MushafPageIndex.fromJson(const {
        'styles': {
          'kemenag': {
            'pageCount': 2,
            'starts': [
              [1, 1, 1],
              [2, 1, 1],
            ],
          },
        },
      }, MushafStyle.kemenag);

      expect(parsed.pageCount, 2);
      expect(parsed.startOf(2).surah, 2);
      expect(parsed.style, MushafStyle.kemenag);
    });
  });
}
