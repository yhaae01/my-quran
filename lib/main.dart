import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/models/bookmark_model.dart';

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
  ]);

  runApp(const ProviderScope(child: QuranApp()));
}
