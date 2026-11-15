import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/hadith.dart';
import 'core_providers.dart';

/// Provides a randomly chosen hadith for the day.
final FutureProvider<Hadith> dailyHadithProvider = FutureProvider<Hadith>((
  ref,
) async {
  final getRandomHadith = ref.watch(getRandomHadithProvider);
  return getRandomHadith();
});

/// Provides all cached / bundled hadiths.
final FutureProvider<List<Hadith>> hadithListProvider =
    FutureProvider<List<Hadith>>((ref) async {
      final getHadiths = ref.watch(getHadithsProvider);
      return getHadiths();
    });
