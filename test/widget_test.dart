import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/domain/entities/ayah.dart';
import 'package:my_quran/domain/entities/mushaf.dart';
import 'package:my_quran/domain/entities/surah.dart';
import 'package:my_quran/presentation/widgets/mushaf_page_widget.dart';

void main() {
  testWidgets('mushaf page shows the surah, ayah and page number', (
    tester,
  ) async {
    const surah = Surah(
      number: 1,
      name: 'الفاتحة',
      latinName: 'Al-Fatihah',
      meaning: 'Pembukaan',
      verseCount: 7,
      revelation: 'Mekah',
      description: '',
    );
    const page = MushafPage(
      number: 1,
      juz: 1,
      style: MushafStyle.kemenag,
      surahs: [surah],
      ayahs: [
        Ayah(
          surahNumber: 1,
          number: 1,
          arabic: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
          uthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          translation:
              'Dengan nama Allah Yang Maha Pengasih lagi Maha '
              'Penyayang.',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MushafPageWidget(page: page)),
      ),
    );

    expect(find.text('Hal. 1'), findsOneWidget);
    expect(find.text('Juz 1'), findsOneWidget);
    expect(find.textContaining('الفاتحة'), findsWidgets);
    expect(find.textContaining('بِسْمِ اللّٰهِ'), findsOneWidget);
  });
}
