import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../data/datasources/bookmark_local_data_source.dart';
import '../../data/datasources/adhan_prayer_times_data_source.dart';
import '../../data/datasources/challenge_remote_data_source.dart';
import '../../data/datasources/device_location_data_source.dart';
import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/datasources/indonesia_region_local_data_source.dart';
import '../../data/datasources/prayer_notification_data_source.dart';
import '../../data/datasources/prayer_widget_data_source.dart';
import '../../data/datasources/quran_local_data_source.dart';
import '../../data/datasources/quran_remote_data_source.dart';
import '../../data/datasources/reading_progress_local_data_source.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/repositories/audio_download_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/bookmark_repository_impl.dart';
import '../../data/repositories/challenge_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/mushaf_repository_impl.dart';
import '../../data/repositories/prayer_reminder_repository_impl.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import '../../data/repositories/prayer_widget_repository_impl.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../data/repositories/region_repository_impl.dart';
import '../../data/repositories/reading_progress_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/mushaf_repository.dart';
import '../../domain/repositories/prayer_reminder_repository.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/repositories/prayer_widget_repository.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../../domain/repositories/region_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/bookmark_usecases.dart';
import '../../domain/usecases/challenge_usecases.dart';
import '../../domain/usecases/prayer_usecases.dart';
import '../../domain/usecases/quran_usecases.dart';
import '../../domain/usecases/reading_progress_usecases.dart';
import '../../data/datasources/hadith_local_data_source.dart';
import '../../data/datasources/hadith_notification_data_source.dart';
import '../../data/repositories/hadith_repository_impl.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../../domain/usecases/hadith_usecases.dart';

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

final Provider<Box<dynamic>> hadithCacheBoxProvider = Provider<Box<dynamic>>(
  (ref) => Hive.box<dynamic>(HiveBoxes.hadithCache),
);

/// Set by `main()` once `Firebase.initializeApp()` succeeds. The challenge
/// screens stay disabled instead of crashing when Firebase is not configured.
final Provider<bool> firebaseReadyProvider = Provider<bool>((ref) => false);

final Provider<FirebaseAuth> firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final Provider<FirebaseFirestore> firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (ref) => AuthRepositoryImpl(
        FirebaseAuthDataSource(ref.watch(firebaseAuthProvider)),
      ),
    );

final Provider<ReadingProgressRepository> readingProgressRepositoryProvider =
    Provider<ReadingProgressRepository>(
      (ref) => ReadingProgressRepositoryImpl(
        ReadingProgressLocalDataSource(ref.watch(settingsBoxProvider)),
      ),
    );

final Provider<ChallengeRepository> challengeRepositoryProvider =
    Provider<ChallengeRepository>(
      (ref) => ChallengeRepositoryImpl(
        ChallengeRemoteDataSource(ref.watch(firestoreProvider)),
        ref.watch(authRepositoryProvider),
        ref.watch(readingProgressRepositoryProvider),
      ),
    );

final Provider<AudioDownloadRepository> audioDownloadRepositoryProvider =
    Provider<AudioDownloadRepository>((ref) => AudioDownloadRepository());

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

final Provider<AdhanPrayerTimesDataSource> adhanPrayerTimesDataSourceProvider =
    Provider<AdhanPrayerTimesDataSource>((ref) => AdhanPrayerTimesDataSource());

final Provider<PrayerTimesRepository> prayerTimesRepositoryProvider =
    Provider<PrayerTimesRepository>(
      (ref) => PrayerTimesRepositoryImpl(
        ref.watch(adhanPrayerTimesDataSourceProvider),
      ),
    );

final Provider<DeviceLocationDataSource> deviceLocationDataSourceProvider =
    Provider<DeviceLocationDataSource>((ref) => DeviceLocationDataSource());

final Provider<LocationRepository> locationRepositoryProvider =
    Provider<LocationRepository>(
      (ref) =>
          LocationRepositoryImpl(ref.watch(deviceLocationDataSourceProvider)),
    );

final Provider<IndonesiaRegionLocalDataSource>
indonesiaRegionLocalDataSourceProvider = Provider(
  (ref) => IndonesiaRegionLocalDataSource(rootBundle),
);

final Provider<RegionRepository> regionRepositoryProvider =
    Provider<RegionRepository>(
      (ref) => RegionRepositoryImpl(
        ref.watch(indonesiaRegionLocalDataSourceProvider),
      ),
    );

final Provider<PrayerNotificationDataSource>
prayerNotificationDataSourceProvider = Provider<PrayerNotificationDataSource>(
  (ref) => PrayerNotificationDataSource(),
);

final Provider<PrayerReminderRepository> prayerReminderRepositoryProvider =
    Provider<PrayerReminderRepository>(
      (ref) => PrayerReminderRepositoryImpl(
        ref.watch(prayerNotificationDataSourceProvider),
      ),
    );

final Provider<PrayerWidgetDataSource> prayerWidgetDataSourceProvider =
    Provider<PrayerWidgetDataSource>((ref) => PrayerWidgetDataSource());

final Provider<PrayerWidgetRepository> prayerWidgetRepositoryProvider =
    Provider<PrayerWidgetRepository>(
      (ref) =>
          PrayerWidgetRepositoryImpl(ref.watch(prayerWidgetDataSourceProvider)),
    );

final Provider<GetPrayerSchedule> getPrayerScheduleProvider =
    Provider<GetPrayerSchedule>(
      (ref) => GetPrayerSchedule(ref.watch(prayerTimesRepositoryProvider)),
    );

final Provider<DetectCurrentLocation> detectCurrentLocationProvider =
    Provider<DetectCurrentLocation>(
      (ref) => DetectCurrentLocation(ref.watch(locationRepositoryProvider)),
    );

final Provider<RequestPrayerNotificationPermission>
requestPrayerNotificationPermissionProvider =
    Provider<RequestPrayerNotificationPermission>(
      (ref) => RequestPrayerNotificationPermission(
        ref.watch(prayerReminderRepositoryProvider),
      ),
    );

final Provider<SyncPrayerReminders> syncPrayerRemindersProvider =
    Provider<SyncPrayerReminders>(
      (ref) => SyncPrayerReminders(ref.watch(prayerReminderRepositoryProvider)),
    );

final Provider<SyncPrayerWidget> syncPrayerWidgetProvider =
    Provider<SyncPrayerWidget>(
      (ref) => SyncPrayerWidget(ref.watch(prayerWidgetRepositoryProvider)),
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

final Provider<WatchAuthState> watchAuthStateProvider =
    Provider<WatchAuthState>(
      (ref) => WatchAuthState(ref.watch(authRepositoryProvider)),
    );

final Provider<SignInAnonymously> signInAnonymouslyProvider =
    Provider<SignInAnonymously>(
      (ref) => SignInAnonymously(ref.watch(authRepositoryProvider)),
    );

final Provider<SignInWithEmail> signInWithEmailProvider =
    Provider<SignInWithEmail>(
      (ref) => SignInWithEmail(ref.watch(authRepositoryProvider)),
    );

final Provider<RegisterWithEmail> registerWithEmailProvider =
    Provider<RegisterWithEmail>(
      (ref) => RegisterWithEmail(ref.watch(authRepositoryProvider)),
    );

final Provider<UpdateDisplayName> updateDisplayNameProvider =
    Provider<UpdateDisplayName>(
      (ref) => UpdateDisplayName(ref.watch(authRepositoryProvider)),
    );

final Provider<SignOut> signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final Provider<CreateReadingGroup> createReadingGroupProvider =
    Provider<CreateReadingGroup>(
      (ref) => CreateReadingGroup(ref.watch(challengeRepositoryProvider)),
    );

final Provider<JoinReadingGroup> joinReadingGroupProvider =
    Provider<JoinReadingGroup>(
      (ref) => JoinReadingGroup(ref.watch(challengeRepositoryProvider)),
    );

final Provider<WatchMyGroups> watchMyGroupsProvider = Provider<WatchMyGroups>(
  (ref) => WatchMyGroups(ref.watch(challengeRepositoryProvider)),
);

final Provider<WatchReadingGroup> watchReadingGroupProvider =
    Provider<WatchReadingGroup>(
      (ref) => WatchReadingGroup(ref.watch(challengeRepositoryProvider)),
    );

final Provider<WatchGroupMembers> watchGroupMembersProvider =
    Provider<WatchGroupMembers>(
      (ref) => WatchGroupMembers(ref.watch(challengeRepositoryProvider)),
    );

final Provider<SyncReadingProgress> syncReadingProgressProvider =
    Provider<SyncReadingProgress>(
      (ref) => SyncReadingProgress(ref.watch(challengeRepositoryProvider)),
    );

final Provider<LeaveReadingGroup> leaveReadingGroupProvider =
    Provider<LeaveReadingGroup>(
      (ref) => LeaveReadingGroup(ref.watch(challengeRepositoryProvider)),
    );

final Provider<DeleteReadingGroup> deleteReadingGroupProvider =
    Provider<DeleteReadingGroup>(
      (ref) => DeleteReadingGroup(ref.watch(challengeRepositoryProvider)),
    );

final Provider<LoadReadingProgress> loadReadingProgressProvider =
    Provider<LoadReadingProgress>(
      (ref) =>
          LoadReadingProgress(ref.watch(readingProgressRepositoryProvider)),
    );

final Provider<SaveReadingProgress> saveReadingProgressProvider =
    Provider<SaveReadingProgress>(
      (ref) =>
          SaveReadingProgress(ref.watch(readingProgressRepositoryProvider)),
    );

final Provider<HadithLocalDataSource> hadithLocalDataSourceProvider =
    Provider<HadithLocalDataSource>(
      (ref) => HadithLocalDataSource(
        bundle: rootBundle,
        box: ref.watch(hadithCacheBoxProvider),
      ),
    );

final Provider<HadithRepository> hadithRepositoryProvider =
    Provider<HadithRepository>(
      (ref) => HadithRepositoryImpl(ref.watch(hadithLocalDataSourceProvider)),
    );

final Provider<HadithNotificationDataSource>
hadithNotificationDataSourceProvider = Provider<HadithNotificationDataSource>(
  (ref) => HadithNotificationDataSource(),
);

final Provider<GetRandomHadith> getRandomHadithProvider =
    Provider<GetRandomHadith>(
      (ref) => GetRandomHadith(ref.watch(hadithRepositoryProvider)),
    );

final Provider<GetHadiths> getHadithsProvider = Provider<GetHadiths>(
  (ref) => GetHadiths(ref.watch(hadithRepositoryProvider)),
);

final Provider<ScheduleDailyHadithNotification>
scheduleDailyHadithNotificationProvider =
    Provider<ScheduleDailyHadithNotification>(
      (ref) => ScheduleDailyHadithNotification(
        repository: ref.watch(hadithRepositoryProvider),
        notificationDataSource: ref.watch(hadithNotificationDataSourceProvider),
      ),
    );
