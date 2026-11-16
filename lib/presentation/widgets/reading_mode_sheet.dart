import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/mushaf_reader_page.dart';
import '../pages/surah_reader_page.dart';
import '../providers/core_providers.dart';
import '../providers/settings_providers.dart';

/// How the reader wants to open a verse or the last reading position.
enum ReadingMode {
  ayah,
  mushaf;

  String get label => switch (this) {
    ReadingMode.ayah => 'Mode per Ayat',
    ReadingMode.mushaf => 'Mode Mushaf',
  };

  String get description => switch (this) {
    ReadingMode.ayah => 'Arab dan terjemahan, satu ayat per baris',
    ReadingMode.mushaf => 'Halaman mushaf 604 halaman',
  };

  IconData get icon => switch (this) {
    ReadingMode.ayah => Icons.format_list_bulleted_rounded,
    ReadingMode.mushaf => Icons.auto_stories_outlined,
  };
}

/// Asks the reader which view to use instead of silently defaulting to Ayah
/// mode. Returns null when the sheet is dismissed.
Future<ReadingMode?> showReadingModeSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  return showModalBottomSheet<ReadingMode>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ReadingModeSheet(title: title, subtitle: subtitle),
  );
}

/// Lets the reader choose Ayah or Mushaf mode, then opens [surahNumber] at
/// [verseNumber] in that mode.
Future<void> openVerseInReadingMode(
  BuildContext context,
  WidgetRef ref, {
  required int surahNumber,
  required int verseNumber,
  String? surahName,
  bool reportInitialAyah = true,
}) async {
  final mode = await showReadingModeSheet(
    context,
    title: 'Buka bacaan',
    subtitle: surahName == null
        ? 'Surah $surahNumber • Ayat $verseNumber'
        : '$surahName • Ayat $verseNumber',
  );
  if (mode == null || !context.mounted) return;

  switch (mode) {
    case ReadingMode.ayah:
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SurahReaderPage(
            surahNumber: surahNumber,
            initialSurahName: surahName,
            initialVerseNumber: verseNumber,
            reportInitialAyah: reportInitialAyah,
            // Back from a mode the reader did not reach through the surah tab
            // should land on the surah list, not on the home dashboard.
            backToSurahList: true,
          ),
        ),
      );
    case ReadingMode.mushaf:
      final style = ref.read(settingsProvider).mushafStyle;
      final page = await ref.read(locateMushafPageProvider)(
        style,
        surah: surahNumber,
        ayah: verseNumber,
      );
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MushafReaderPage(initialPage: page),
        ),
      );
  }
}

class _ReadingModeSheet extends StatelessWidget {
  const _ReadingModeSheet({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Pilih mode baca',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            for (final mode in ReadingMode.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ModeOption(
                  mode: mode,
                  onTap: () => Navigator.of(context).pop(mode),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({required this.mode, required this.onTap});

  final ReadingMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(mode.icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
