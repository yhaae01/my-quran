import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/mushaf.dart';
import '../../domain/entities/surah.dart';
import '../providers/audio_provider.dart';
import '../providers/core_providers.dart';
import '../providers/quran_providers.dart';
import '../providers/reading_progress_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/ayah_tile.dart';
import '../widgets/common_views.dart';
import '../widgets/font_size_sheet.dart';
import '../widgets/immersive_reader.dart';
import '../widgets/quran_text.dart';
import '../widgets/reciter_sheet.dart';
import 'mushaf_reader_page.dart';
import 'surah_list_page.dart';

class SurahReaderPage extends ConsumerWidget {
  const SurahReaderPage({
    super.key,
    required this.surahNumber,
    this.initialSurahName,
    this.initialVerseNumber,
    this.reportInitialAyah = true,
    this.backToSurahList = false,
  });

  final int surahNumber;
  final String? initialSurahName;

  /// When provided, the reader opens at this verse and highlights it.
  final int? initialVerseNumber;

  /// Whether landing on [initialVerseNumber] counts as reading progress.
  ///
  /// Opening a personal bookmark passes `false`: saved references stay
  /// independent from the real-time reading challenge, which must only follow
  /// the reader's own active position. Scrolling afterwards is still tracked.
  final bool reportInitialAyah;

  /// Whether back should land on the surah list.
  ///
  /// Ayah mode is reachable from the dashboard and from a bookmark on another
  /// tab, where the default pop would return all the way to that tab. Those
  /// entries set this so back reveals the surah list instead.
  final bool backToSurahList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(surahDetailProvider(surahNumber));
    final detail = detailAsync.value;
    final settings = ref.watch(settingsProvider);
    final style = settings.mushafStyle;
    final showTranslation = settings.showTranslation;

    ref.listen<String?>(ayahAudioProvider.select((state) => state.error), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return PopScope(
      // Blocks the implicit back gesture/app-bar arrow so the reader can
      // replace itself with the surah list instead of leaving the tab stack.
      canPop: !backToSurahList,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const SurahListPage()),
        );
      },
      child: ImmersiveReader(
        builder: (context, immersive, toggleImmersive) => Scaffold(
          appBar: immersive
              ? null
              : AppBar(
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
                          '${detail.surah.verseCount} ayat • '
                          '${detail.surah.revelation}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Qori & unduhan audio',
                      onPressed: () =>
                          showReciterSheet(context, detail: detail),
                      icon: const Icon(Icons.record_voice_over_outlined),
                    ),
                    IconButton(
                      tooltip: showTranslation
                          ? 'Sembunyikan terjemahan'
                          : 'Tampilkan terjemahan',
                      onPressed: () => ref
                          .read(settingsProvider.notifier)
                          .toggleTranslation(),
                      icon: Icon(
                        showTranslation
                            ? Icons.subtitles_outlined
                            : Icons.subtitles_off_outlined,
                        color: showTranslation
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ukuran teks Arab',
                      onPressed: () => showFontSizeSheet(context),
                      icon: const Icon(Icons.format_size),
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
                    IconButton(
                      tooltip: 'Mode baca penuh',
                      onPressed: toggleImmersive,
                      icon: const Icon(Icons.fullscreen_rounded),
                    ),
                  ],
                ),
          body: SafeArea(
            top: immersive,
            bottom: false,
            child: detailAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(surahDetailProvider(surahNumber)),
              ),
              data: (detail) {
                return _AyahList(
                  detail: detail,
                  style: style,
                  topPadding: immersive ? 58 : 0,
                  target: initialVerseNumber,
                  reportInitialAyah: reportInitialAyah,
                  onAyahVisible: (ayah) {
                    unawaited(
                      ref
                          .read(readingProgressProvider.notifier)
                          .record(
                            surahNumber: detail.surah.number,
                            ayahNumber: ayah.number,
                            surahName: detail.surah.latinName,
                          ),
                    );
                  },
                  onPlayAyah: (index) {
                    unawaited(
                      ref
                          .read(ayahAudioProvider.notifier)
                          .toggleAyah(
                            detail: detail,
                            ayahIndex: index,
                            reciter: ref.read(settingsProvider).reciter,
                          ),
                    );
                  },
                );
              },
            ),
          ),
        ),
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

/// Scrollable ayah list that reports the first visible verse so the reading
/// challenge can follow along without storing anything on every scroll tick.
class _AyahList extends StatefulWidget {
  const _AyahList({
    required this.detail,
    required this.style,
    required this.target,
    required this.onAyahVisible,
    required this.onPlayAyah,
    this.reportInitialAyah = true,
    this.topPadding = 0,
  });

  final SurahDetail detail;
  final MushafStyle style;
  final int? target;

  /// When false, the auto-jump to [target] is not reported as progress, so a
  /// bookmark tap cannot move the challenge leaderboard.
  final bool reportInitialAyah;

  /// Leaves room for the floating immersive-mode exit button.
  final double topPadding;
  final ValueChanged<Ayah> onAyahVisible;
  final ValueChanged<int> onPlayAyah;

  @override
  State<_AyahList> createState() => _AyahListState();
}

class _AyahListState extends State<_AyahList> {
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  int? _lastReportedAyah;
  bool _skippedInitialAyah = false;

  @override
  void initState() {
    super.initState();
    _positions.itemPositions.addListener(_reportVisibleAyah);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_reportVisibleAyah);
    super.dispose();
  }

  void _reportVisibleAyah() {
    int? firstVisible;
    for (final position in _positions.itemPositions.value) {
      if (position.itemTrailingEdge <= 0) continue;
      if (firstVisible == null || position.index < firstVisible) {
        firstVisible = position.index;
      }
    }
    // Index 0 is the surah header, verse tiles start at index 1.
    if (firstVisible == null ||
        firstVisible < 1 ||
        firstVisible > widget.detail.ayahs.length) {
      return;
    }
    final ayah = widget.detail.ayahs[firstVisible - 1];
    if (_lastReportedAyah == ayah.number) return;
    if (!widget.reportInitialAyah &&
        !_skippedInitialAyah &&
        ayah.number == widget.target) {
      // The bookmark jump itself is a personal reference, not reading progress.
      _skippedInitialAyah = true;
      _lastReportedAyah = ayah.number;
      return;
    }
    _lastReportedAyah = ayah.number;
    widget.onAyahVisible(ayah);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    return ScrollablePositionedList.builder(
      padding: EdgeInsets.only(top: widget.topPadding, bottom: 32),
      itemPositionsListener: _positions,
      itemCount: widget.detail.ayahs.length + 1,
      initialScrollIndex: target == null
          ? 0
          : target.clamp(1, widget.detail.ayahs.length).toInt(),
      initialAlignment: 0.03,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SurahHeader(surah: widget.detail.surah, style: widget.style);
        }
        final ayah = widget.detail.ayahs[index - 1];
        final ayahIndex = index - 1;
        return AyahTile(
          surah: widget.detail.surah,
          ayah: ayah,
          highlighted: target == ayah.number,
          onPlay: () => widget.onPlayAyah(ayahIndex),
        );
      },
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
