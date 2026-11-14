import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/mushaf.dart';
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
