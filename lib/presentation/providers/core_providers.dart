import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../data/datasources/bookmark_local_data_source.dart';
import '../../data/datasources/quran_local_data_source.dart';
import '../../data/datasources/quran_remote_data_source.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/repositories/bookmark_repository_impl.dart';
import '../../data/repositories/mushaf_repository_impl.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../domain/repositories/mushaf_repository.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/bookmark_usecases.dart';
import '../../domain/usecases/quran_usecases.dart';

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.dispose);
  return client;
});

final Provider<Box<BookmarkModel>> bookmarkBoxProvider =
    Provider<Box<BookmarkModel>>(
      (ref) => Hive.box<BookmarkModel>(HiveBoxes.bookmarks),
    );

final Provider<Box<dynamic>> quranCacheBoxProvider = Provider<Box<dynamic>>(
  (ref) => Hive.box<dynamic>(HiveBoxes.quranCache),
);

final Provider<Box<dynamic>> settingsBoxProvider = Provider<Box<dynamic>>(
  (ref) => Hive.box<dynamic>(HiveBoxes.settings),
);

final Provider<QuranRemoteDataSource> quranRemoteDataSourceProvider =
    Provider<QuranRemoteDataSource>(
      (ref) => QuranRemoteDataSource(ref.watch(apiClientProvider)),
    );

final Provider<QuranLocalDataSource> quranLocalDataSourceProvider =
    Provider<QuranLocalDataSource>(
      (ref) => QuranLocalDataSource(ref.watch(quranCacheBoxProvider)),
    );

final Provider<QuranRepository> quranRepositoryProvider =
    Provider<QuranRepository>(
      (ref) => QuranRepositoryImpl(
        remote: ref.watch(quranRemoteDataSourceProvider),
        local: ref.watch(quranLocalDataSourceProvider),
      ),
    );

final Provider<MushafRepository> mushafRepositoryProvider =
    Provider<MushafRepository>(
      (ref) => MushafRepositoryImpl(
        quranRepository: ref.watch(quranRepositoryProvider),
        assets: rootBundle,
      ),
    );

final Provider<BookmarkRepository> bookmarkRepositoryProvider =
    Provider<BookmarkRepository>(
      (ref) => BookmarkRepositoryImpl(
        BookmarkLocalDataSource(ref.watch(bookmarkBoxProvider)),
      ),
    );

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (ref) => SettingsRepositoryImpl(ref.watch(settingsBoxProvider)),
    );

final Provider<GetSurahs> getSurahsProvider = Provider<GetSurahs>(
  (ref) => GetSurahs(ref.watch(quranRepositoryProvider)),
);

final Provider<GetSurahDetail> getSurahDetailProvider =
    Provider<GetSurahDetail>(
      (ref) => GetSurahDetail(ref.watch(quranRepositoryProvider)),
    );

final Provider<GetMushafPage> getMushafPageProvider = Provider<GetMushafPage>(
  (ref) => GetMushafPage(ref.watch(mushafRepositoryProvider)),
);

final Provider<LocateMushafPage> locateMushafPageProvider =
    Provider<LocateMushafPage>(
      (ref) => LocateMushafPage(ref.watch(mushafRepositoryProvider)),
    );

final Provider<GetBookmarks> getBookmarksProvider = Provider<GetBookmarks>(
  (ref) => GetBookmarks(ref.watch(bookmarkRepositoryProvider)),
);

final Provider<SaveBookmark> saveBookmarkProvider = Provider<SaveBookmark>(
  (ref) => SaveBookmark(ref.watch(bookmarkRepositoryProvider)),
);

final Provider<DeleteBookmark> deleteBookmarkProvider =
    Provider<DeleteBookmark>(
      (ref) => DeleteBookmark(ref.watch(bookmarkRepositoryProvider)),
    );
