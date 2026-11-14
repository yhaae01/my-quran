import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/surah.dart';
import '../providers/quran_providers.dart';
import '../widgets/common_views.dart';
import '../widgets/surah_tile.dart';
import 'surah_reader_page.dart';

class SurahListPage extends ConsumerWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Al-Qur'an"),
        actions: [
          IconButton(
            tooltip: 'Muat ulang daftar surah',
            onPressed: () => ref.read(surahListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: surahsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(surahListProvider.notifier).refresh(),
        ),
        data: (surahs) => _SurahListView(surahs: surahs),
      ),
    );
  }
}

class _SurahListView extends ConsumerWidget {
  const _SurahListView({required this.surahs});

  final List<Surah> surahs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(surahListProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: surahs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final surah = surahs[index];
          return SurahTile(
            surah: surah,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SurahReaderPage(
                    surahNumber: surah.number,
                    initialSurahName: surah.latinName,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
