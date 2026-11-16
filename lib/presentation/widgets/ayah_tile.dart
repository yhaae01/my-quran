import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/audio_timing.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/surah.dart';
import '../providers/audio_provider.dart';
import '../providers/bookmark_providers.dart';
import '../providers/settings_providers.dart';
import 'bookmark_sheet.dart';

class AyahTile extends ConsumerWidget {
  const AyahTile({
    super.key,
    required this.surah,
    required this.ayah,
    required this.onPlay,
    this.highlighted = false,
  });

  final Surah surah;
  final Ayah ayah;

  /// Starts the surah queue at this ayah, or pauses/resumes it when this ayah
  /// is already the active track.
  final VoidCallback? onPlay;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final bookmark = ref.watch(
      bookmarkAtProvider((surah: ayah.surahNumber, verse: ayah.number)),
    );

    // Only the active tile rebuilds on position ticks; the selector compares
    // structurally-equal records so the other 285 tiles stay idle.
    final playback = ref.watch(
      ayahAudioProvider.select((state) {
        final active =
            state.surahNumber == ayah.surahNumber &&
            state.ayahNumber == ayah.number;
        return (
          active: active,
          isPlaying: active && state.isPlaying,
          isLoading: active && state.isLoading,
          position: active ? state.position : Duration.zero,
          duration: active ? state.duration : Duration.zero,
        );
      }),
    );
    final isActive = playback.active;
    final text = ayah.arabicFor(settings.mushafStyle);
    final words = isActive ? text.split(' ') : const <String>[];
    final activeWord = activeWordIndex(
      words: words,
      position: playback.position,
      duration: playback.duration,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: isActive
            ? scheme.primaryContainer.withValues(alpha: 0.32)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? AppColors.gold
              : isActive
              ? scheme.primary.withValues(alpha: 0.75)
              : scheme.outlineVariant.withValues(alpha: 0.55),
          width: highlighted || isActive ? 1.8 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _VerseBadge(number: ayah.number, active: isActive),
                if (bookmark != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: Bookmark.activeLabel,
                    child: Icon(
                      Icons.bookmark_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  tooltip: playback.isPlaying ? 'Jeda audio' : 'Putar audio',
                  onPressed: playback.isLoading ? null : onPlay,
                  icon: playback.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          playback.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_outline,
                          color: isActive
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                ),
                IconButton(
                  tooltip: bookmark == null ? 'Tandai ayat' : 'Ubah penanda',
                  onPressed: () => showBookmarkSheet(
                    context,
                    surah: surah,
                    ayah: ayah,
                    existing: bookmark,
                  ),
                  icon: Icon(
                    bookmark == null
                        ? Icons.bookmark_add_outlined
                        : Icons.bookmark_rounded,
                    color: bookmark == null
                        ? scheme.onSurfaceVariant
                        : scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text.rich(
                activeWord == null
                    ? TextSpan(text: text)
                    : TextSpan(
                        children: [
                          for (var index = 0; index < words.length; index++)
                            TextSpan(
                              text: index == words.length - 1
                                  ? words[index]
                                  : '${words[index]} ',
                              style: index == activeWord
                                  ? TextStyle(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w700,
                                      backgroundColor: scheme.primary
                                          .withValues(alpha: 0.16),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: settings.mushafStyle.fontFamily,
                  fontSize: settings.arabicFontSize,
                  height: 1.9,
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (settings.showTranslation) ...[
              const SizedBox(height: 12),
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
                height: 1,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  ayah.translation,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerseBadge extends StatelessWidget {
  const _VerseBadge({required this.number, this.active = false});

  final int number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? scheme.primary
            : scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Ayat $number',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: active ? scheme.onPrimary : scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
