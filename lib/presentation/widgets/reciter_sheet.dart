import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah.dart';
import '../providers/audio_download_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/settings_providers.dart';

/// Shows the reciter picker. When [detail] is provided the sheet also offers
/// offline download controls for the surah currently open in the reader.
Future<void> showReciterSheet(BuildContext context, {SurahDetail? detail}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ReciterSheet(detail: detail),
  );
}

class _ReciterSheet extends ConsumerWidget {
  const _ReciterSheet({this.detail});

  final SurahDetail? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(
      settingsProvider.select((settings) => settings.reciter),
    );
    final downloadsAsync = ref.watch(audioDownloadsProvider);
    final downloads = downloadsAsync.value;

    ref.listen<AsyncValue<AudioDownloadState>>(audioDownloadsProvider, (
      previous,
      next,
    ) {
      final error = next.value?.error;
      if (error == null || error == previous?.value?.error) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    });

    final surah = detail?.surah;
    final progress = surah == null
        ? null
        : downloads?.progressFor(selected.id, surah.number);
    final isDownloaded = surah == null
        ? false
        : downloads?.isSurahDownloaded(
                selected.id,
                surah.number,
                detail?.ayahs.length ?? surah.verseCount,
              ) ??
              false;
    final audioUrls = detail == null
        ? const <String>[]
        : [for (final ayah in detail!.ayahs) ayah.audioUrlFor(selected)];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qori & audio murottal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih qori favorit. Saat audio diputar, bacaan berlanjut '
                    'otomatis ke ayat berikutnya.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                itemCount: Reciter.all.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final reciter = Reciter.all[index];
                  final isSelected = reciter.id == selected.id;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        reciter.id,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      reciter.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      reciter.arabicName,
                      textDirection: TextDirection.rtl,
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      if (isSelected) return;
                      ref.read(settingsProvider.notifier).setReciter(reciter);
                      // The queued surah belongs to the old reciter; stop it so
                      // the next play starts cleanly with the new voice.
                      ref.read(ayahAudioProvider.notifier).stop();
                    },
                  );
                },
              ),
            ),
            if (surah != null)
              _DownloadSection(
                surah: surah,
                reciter: selected,
                audioUrls: audioUrls,
                progress: progress,
                isDownloaded: isDownloaded,
                isLoading: downloadsAsync.isLoading,
              ),
          ],
        ),
      ),
    );
  }
}

class _DownloadSection extends ConsumerWidget {
  const _DownloadSection({
    required this.surah,
    required this.reciter,
    required this.audioUrls,
    required this.progress,
    required this.isDownloaded,
    required this.isLoading,
  });

  final Surah surah;
  final Reciter reciter;
  final List<String> audioUrls;
  final double? progress;
  final bool isDownloaded;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDownloading = progress != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isDownloaded
                    ? Icons.offline_pin_outlined
                    : Icons.download_for_offline_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Audio ${surah.latinName} · ${surah.verseCount} ayat',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isDownloaded
                ? 'Tersimpan di perangkat dan siap diputar tanpa internet.'
                : 'Unduh seluruh ayat surah ini dari qori ${reciter.name} untuk '
                      'diputar offline.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (isDownloading) ...[
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              'Mengunduh ${(progress! * 100).round()}%',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (isDownloaded)
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(audioDownloadsProvider.notifier)
                  .deleteSurah(reciter: reciter, surahNumber: surah.number),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus unduhan'),
            )
          else if (kIsWeb)
            Text(
              'Unduhan offline tersedia di aplikasi Android dan iOS.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            FilledButton.icon(
              onPressed: isLoading || isDownloading || audioUrls.isEmpty
                  ? null
                  : () {
                      ref
                          .read(audioDownloadsProvider.notifier)
                          .downloadSurah(
                            reciter: reciter,
                            surahNumber: surah.number,
                            audioUrls: audioUrls,
                          );
                    },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Unduh audio surah ini'),
            ),
        ],
      ),
    );
  }
}
