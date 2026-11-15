import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/models/bookmark_model.dart';
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
