import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/datasources/adhan_prayer_times_data_source.dart';
import 'data/datasources/prayer_widget_background.dart';
import 'data/datasources/prayer_widget_data_source.dart';
import 'data/models/bookmark_model.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'presentation/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BookmarkModelAdapter());
  }
  await Future.wait([
    Hive.openBox<BookmarkModel>(HiveBoxes.bookmarks),
    Hive.openBox<dynamic>(HiveBoxes.quranCache),
    Hive.openBox<dynamic>(HiveBoxes.settings),
    Hive.openBox<dynamic>(HiveBoxes.hadithCache),
  ]);

  // A widget pinned before the first launch would otherwise stay on its native
  // placeholders until the user opens the prayer tab. Write a real schedule as
  // early as possible; failures fall back to the provider's placeholders.
  try {
    final preferences = SettingsRepositoryImpl(
      Hive.box<dynamic>(HiveBoxes.settings),
    ).load().prayer;
    final schedule = AdhanPrayerTimesDataSource().calculate(
      locationLabel: preferences.resolvedLocationLabel,
      latitude: preferences.resolvedLatitude,
      longitude: preferences.resolvedLongitude,
      timeZoneId: preferences.resolvedTimeZoneId,
    );
    await PrayerWidgetDataSource().update(schedule, preferences);
  } catch (error) {
    debugPrint('Widget waktu shalat belum dapat disiapkan: $error');
  }

  await registerPrayerWidgetBackgroundCallback();

  // Configured by `flutterfire configure`: google-services.json on Android and
  // GoogleService-Info.plist on iOS. The reader keeps working offline when
  // Firebase cannot start.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (error) {
    debugPrint('Firebase gagal diinisialisasi: $error');
  }

  runApp(
    ProviderScope(
      overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
      child: const QuranApp(),
    ),
  );
}
