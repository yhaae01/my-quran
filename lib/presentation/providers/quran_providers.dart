import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/mushaf.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/surah.dart';
import 'core_providers.dart';

class SurahListNotifier extends AsyncNotifier<List<Surah>> {
  @override
  Future<List<Surah>> build() {
    return ref.watch(getSurahsProvider)();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(getSurahsProvider)(forceRefresh: true),
    );
  }
}

final AsyncNotifierProvider<SurahListNotifier, List<Surah>> surahListProvider =
    AsyncNotifierProvider<SurahListNotifier, List<Surah>>(
      SurahListNotifier.new,
    );

final surahDetailProvider = FutureProvider.family<SurahDetail, int>((
  ref,
  surahNumber,
) {
  return ref.watch(getSurahDetailProvider)(surahNumber);
});

class MushafPageQuery {
  const MushafPageQuery({required this.style, required this.page});

  final MushafStyle style;
  final int page;

  @override
  bool operator ==(Object other) {
    return other is MushafPageQuery &&
        other.style == style &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(style, page);
}

final mushafPageProvider = FutureProvider.family<MushafPage, MushafPageQuery>((
  ref,
  query,
) {
  return ref.watch(getMushafPageProvider)(query.style, query.page);
});

/// Juz label for every surah in one mushaf layout.
///
/// "Juz 1" for a surah inside one juz, "Juz 1–3" when it spans several. The
/// whole map is loaded once and shared by the surah list and reader header.
final surahJuzRangesProvider =
    FutureProvider.family<Map<int, String>, MushafStyle>((ref, style) async {
      final repository = ref.watch(mushafRepositoryProvider);
      final ranges = <int, String>{};
      for (var surah = 1; surah <= surahVerseCounts.length; surah++) {
        final verseCount = surahVerseCounts[surah - 1];
        final first = await repository.juzForVerse(
          style,
          surah: surah,
          ayah: 1,
        );
        final last = verseCount <= 1
            ? first
            : await repository.juzForVerse(
                style,
                surah: surah,
                ayah: verseCount,
              );
        ranges[surah] = first == last ? 'Juz $first' : 'Juz $first–$last';
      }
      return ranges;
    });
