import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/mushaf.dart';
import '../../domain/entities/surah.dart';
import '../providers/audio_provider.dart';
import '../providers/core_providers.dart';
import '../providers/quran_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/ayah_tile.dart';
import '../widgets/common_views.dart';
import '../widgets/font_size_sheet.dart';
import '../widgets/mushaf_style_sheet.dart';
import '../widgets/quran_text.dart';
import 'mushaf_reader_page.dart';

class SurahReaderPage extends ConsumerWidget {
  const SurahReaderPage({
    super.key,
    required this.surahNumber,
    this.initialSurahName,
    this.initialVerseNumber,
  });

  final int surahNumber;
  final String? initialSurahName;

  /// When provided, the reader opens at this verse and highlights it.
  final int? initialVerseNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(surahDetailProvider(surahNumber));
    final detail = detailAsync.value;
    final style = ref.watch(settingsProvider).mushafStyle;

    ref.listen<String?>(ayahAudioProvider.select((state) => state.error), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail?.surah.latinName ??
                  initialSurahName ??
                  'Surah $surahNumber',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (detail != null)
              Text(
                '${detail.surah.verseCount} ayat • ${detail.surah.revelation}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ukuran teks Arab',
            onPressed: () => showFontSizeSheet(context),
            icon: const Icon(Icons.format_size),
          ),
          IconButton(
            tooltip: 'Gaya mushaf',
            onPressed: () => showMushafStyleSheet(context),
            icon: const Icon(Icons.palette_outlined),
          ),
          IconButton(
            tooltip: 'Buka di mushaf',
            onPressed: detail == null
                ? null
                : () => _openInMushaf(
                    context,
                    ref,
                    style,
                    surahNumber,
                    initialVerseNumber ?? 1,
                  ),
            icon: const Icon(Icons.auto_stories_outlined),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(surahDetailProvider(surahNumber)),
        ),
        data: (detail) {
          final target = initialVerseNumber;
          return ScrollablePositionedList.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: detail.ayahs.length + 1,
            initialScrollIndex: target == null
                ? 0
                : target.clamp(1, detail.ayahs.length).toInt(),
            initialAlignment: 0.03,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SurahHeader(surah: detail.surah, style: style);
              }
              final ayah = detail.ayahs[index - 1];
              return AyahTile(
                surah: detail.surah,
                ayah: ayah,
                highlighted: target == ayah.number,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openInMushaf(
    BuildContext context,
    WidgetRef ref,
    MushafStyle style,
    int surah,
    int ayah,
  ) async {
    final page = await ref.read(locateMushafPageProvider)(
      style,
      surah: surah,
      ayah: ayah,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MushafReaderPage(initialPage: page),
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah, required this.style});

  final Surah surah;
  final MushafStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showBasmalah = surah.number != 1 && surah.number != 9;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            surah.name,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: style.fontFamily,
              fontSize: 38,
              height: 1.5,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            surah.latinName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.meaning} • ${surah.revelation} • ${surah.verseCount} ayat',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (showBasmalah) ...[
            const SizedBox(height: 16),
            Divider(
              color: AppColors.gold.withValues(alpha: 0.3),
              indent: 24,
              endIndent: 24,
            ),
            const SizedBox(height: 14),
            Text(
              basmalahFor(style),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: style.fontFamily,
                fontSize: 26,
                height: 1.9,
                color: scheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
