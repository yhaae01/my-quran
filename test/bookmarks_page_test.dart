import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/data/models/bookmark_model.dart';
import 'package:my_quran/domain/entities/app_settings.dart';
import 'package:my_quran/domain/entities/bookmark.dart';
import 'package:my_quran/domain/repositories/bookmark_repository.dart';
import 'package:my_quran/domain/repositories/settings_repository.dart';
import 'package:my_quran/presentation/pages/bookmarks_page.dart';
import 'package:my_quran/presentation/providers/core_providers.dart';

class _FakeBookmarkRepository implements BookmarkRepository {
  _FakeBookmarkRepository(this.bookmarks);

  List<Bookmark> bookmarks;

  @override
  Future<List<Bookmark>> getBookmarks() async => List.of(bookmarks);

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {
    bookmarks = [
      bookmark,
      ...bookmarks.where((item) => item.id != bookmark.id),
    ];
  }

  @override
  Future<void> deleteBookmark(String id) async {
    bookmarks = bookmarks.where((item) => item.id != id).toList();
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  AppSettings load() => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

Widget _wrap(BookmarkRepository repository) {
  return ProviderScope(
    overrides: [
      bookmarkRepositoryProvider.overrideWithValue(repository),
      settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
    ],
    child: const MaterialApp(home: BookmarksPage()),
  );
}

void main() {
  final saved = Bookmark(
    id: '2_255',
    surahName: 'Al-Baqarah',
    surahNumber: 2,
    verseNumber: 255,
    arabicText: 'اللّٰهُ لَآ اِلٰهَ اِلَّا هُوَ',
    translation: 'Allah, tidak ada tuhan selain Dia.',
    timestamp: DateTime(2026, 11, 15, 9, 30),
  );

  testWidgets('shows an empty state when no bookmarks are saved', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeBookmarkRepository(const [])));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada penanda'), findsOneWidget);
  });

  testWidgets('renders surah, ayah, label, snippet and timestamp', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeBookmarkRepository([saved])));
    await tester.pumpAndSettle();

    expect(find.text('Surah Al-Baqarah - Ayat 255'), findsOneWidget);
    expect(find.text('Penanda Terakhir'), findsOneWidget);
    expect(find.textContaining('Allah, tidak ada tuhan'), findsOneWidget);
    expect(find.textContaining('09:30'), findsOneWidget);
    expect(find.byTooltip('Hapus penanda'), findsOneWidget);
    expect(find.text('Biru'), findsNothing);
  });

  testWidgets('repairs a bookmark with missing fields instead of crashing', (
    tester,
  ) async {
    final repaired = const BookmarkModel(
      id: 'broken',
      surahNumber: 2,
    ).toEntity();
    await tester.pumpWidget(_wrap(_FakeBookmarkRepository([repaired])));
    await tester.pumpAndSettle();

    expect(find.text('Surah 2 - Ayat 0'), findsOneWidget);
    expect(find.text('Penanda Terakhir'), findsOneWidget);
    expect(find.text('Teks Arab tidak tersedia.'), findsOneWidget);
    expect(find.text('Tanggal tidak tercatat'), findsOneWidget);
  });

  testWidgets('delete button removes the bookmark', (tester) async {
    final repository = _FakeBookmarkRepository([saved]);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hapus penanda'));
    await tester.pumpAndSettle();

    expect(repository.bookmarks, isEmpty);
    expect(find.text('Surah Al-Baqarah - Ayat 255'), findsNothing);
  });
}
