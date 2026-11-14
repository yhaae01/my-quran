import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/surah.dart';
import '../providers/audio_provider.dart';
import '../providers/bookmark_providers.dart';
import '../providers/settings_providers.dart';
import 'bookmark_color_sheet.dart';

class AyahTile extends ConsumerWidget {
  const AyahTile({
    super.key,
    required this.surah,
    required this.ayah,
    this.highlighted = false,
  });

  final Surah surah;
  final Ayah ayah;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final bookmark = ref.watch(
      bookmarkAtProvider((surah: ayah.surahNumber, verse: ayah.number)),
    );
    final audio = ref.watch(ayahAudioProvider);

    final audioUrl = ayah.audioUrl;
    final isCurrent = audioUrl != null && audio.url == audioUrl;
    final isPlaying = isCurrent && audio.isPlaying;
    final isLoading = isCurrent && audio.isLoading;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? AppColors.gold
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          width: highlighted ? 1.8 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _VerseBadge(number: ayah.number),
                const SizedBox(width: 10),
                if (bookmark != null) _BookmarkDot(color: bookmark.color),
                const Spacer(),
                IconButton(
                  tooltip: isPlaying ? 'Jeda audio' : 'Putar audio',
                  onPressed: audioUrl == null || isLoading
                      ? null
                      : () => ref
                            .read(ayahAudioProvider.notifier)
                            .toggle(audioUrl),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_outline,
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                ),
                IconButton(
                  tooltip: bookmark == null ? 'Tandai ayat' : 'Ubah penanda',
                  onPressed: () => showBookmarkColorSheet(
                    context,
                    surah: surah,
                    ayah: ayah,
                    existing: bookmark,
                  ),
                  icon: Icon(
                    bookmark == null
                        ? Icons.bookmark_add_outlined
                        : Icons.bookmark,
                    color: bookmark == null
                        ? theme.colorScheme.onSurfaceVariant
                        : bookmark.color.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                ayah.arabicFor(settings.mushafStyle),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: settings.mushafStyle.fontFamily,
                  fontSize: settings.arabicFontSize,
                  height: 1.9,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              height: 1,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                ayah.translation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseBadge extends StatelessWidget {
  const _VerseBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Ayat $number',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BookmarkDot extends StatelessWidget {
  const _BookmarkDot({required this.color});

  final BookmarkColor color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Penanda ${color.label.toLowerCase()}',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color.color, shape: BoxShape.circle),
      ),
    );
  }
}
