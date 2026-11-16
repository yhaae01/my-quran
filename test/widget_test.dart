import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/domain/entities/ayah.dart';
import 'package:my_quran/domain/entities/bookmark.dart';
import 'package:my_quran/domain/entities/mushaf.dart';
import 'package:my_quran/domain/entities/reading_progress.dart';
import 'package:my_quran/domain/entities/surah.dart';
import 'package:my_quran/domain/repositories/bookmark_repository.dart';
import 'package:my_quran/domain/repositories/reading_progress_repository.dart';
import 'package:my_quran/presentation/providers/core_providers.dart';
import 'package:my_quran/presentation/widgets/mushaf_page_widget.dart';

class _FakeBookmarkRepository implements BookmarkRepository {
  final List<Bookmark> saved = [];

  @override
  Future<List<Bookmark>> getBookmarks() async => List.of(saved);

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {
    saved.add(bookmark);
  }

  @override
  Future<void> deleteBookmark(String id) async {
    saved.removeWhere((bookmark) => bookmark.id == id);
  }
}

class _FakeReadingProgressRepository implements ReadingProgressRepository {
  @override
  ReadingProgress? load() => null;

  @override
  Future<void> save(ReadingProgress progress) async {}
}

const _surah = Surah(
  number: 1,
  name: 'الفاتحة',
  latinName: 'Al-Fatihah',
  meaning: 'Pembukaan',
  verseCount: 7,
  revelation: 'Mekah',
  description: '',
);

const _page = MushafPage(
  number: 1,
  juz: 1,
  style: MushafStyle.kemenag,
  surahs: [_surah],
  ayahs: [
    Ayah(
      surahNumber: 1,
      number: 1,
      arabic: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
      uthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      translation: 'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang.',
    ),
  ],
);

Widget _wrap(_FakeBookmarkRepository repository) {
  return ProviderScope(
    overrides: [
      bookmarkRepositoryProvider.overrideWithValue(repository),
      readingProgressRepositoryProvider.overrideWithValue(
        _FakeReadingProgressRepository(),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: MushafPageWidget(page: _page)),
    ),
  );
}

void main() {
  testWidgets('mushaf page shows the surah, ayah and page number', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeBookmarkRepository()));

    expect(find.text('Hal. 1'), findsOneWidget);
    expect(find.text('Juz 1'), findsOneWidget);
    expect(find.textContaining('الفاتحة'), findsWidgets);
    expect(find.textContaining('بِسْمِ اللّٰهِ'), findsOneWidget);
  });

  testWidgets('tapping an ayah opens its bookmark action sheet', (
    tester,
  ) async {
    final repository = _FakeBookmarkRepository();
    await tester.pumpWidget(_wrap(repository));

    // Arabic text flows right-to-left, so tap near the top-right glyph run
    // rather than the geometric centre of the full-width paragraph.
    final ayahText = find.textContaining('بِسْمِ اللّٰهِ');
    await tester.tapAt(tester.getTopRight(ayahText) + const Offset(-30, 24));
    await tester.pumpAndSettle();

    expect(find.text('Tandai ayat'), findsOneWidget);

    await tester.tap(find.text('Simpan sebagai Penanda Terakhir'));
    await tester.pumpAndSettle();

    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.surahNumber, 1);
    expect(repository.saved.single.verseNumber, 1);
  });
}
