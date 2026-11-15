import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/mushaf.dart';
import '../../domain/entities/surah.dart';
import '../providers/bookmark_providers.dart';
import 'bookmark_badge.dart';

Future<void> showBookmarkColorSheet(
  BuildContext context, {
  required Surah surah,
  required Ayah ayah,
  Bookmark? existing,
  MushafStyle? style,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BookmarkColorSheet(
      surah: surah,
      ayah: ayah,
      existing: existing,
      style: style,
    ),
  );
}

class BookmarkColorSheet extends ConsumerWidget {
  const BookmarkColorSheet({
    super.key,
    required this.surah,
    required this.ayah,
    this.existing,
    this.style,
  });

  final Surah surah;
  final Ayah ayah;
  final Bookmark? existing;

  /// Arabic rasm used by the mushaf that opened this sheet.
  final MushafStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existing == null ? 'Tandai ayat' : 'Ubah penanda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${surah.latinName} • Ayat ${ayah.number}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ayah.arabicFor(style ?? MushafStyle.kemenag),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: (style ?? MushafStyle.kemenag).fontFamily,
                      fontSize: 21,
                      height: 1.8,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ayah.translation,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              existing == null
                  ? 'Pilih emblem penanda'
                  : 'Ganti emblem penanda',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final color in BookmarkColor.values)
                  _ColorChoice(
                    color: color,
                    selected: existing?.color == color,
                    onTap: () => _save(context, ref, color),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Penanda bersifat pribadi: tersimpan di perangkat dan tidak '
              'memengaruhi progres tantangan bacaan Anda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (existing != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  final notifier = ref.read(bookmarksProvider.notifier);
                  await notifier.remove(existing!.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus penanda'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    BookmarkColor color,
  ) async {
    final now = DateTime.now();
    final bookmark = Bookmark(
      id:
          existing?.id ??
          '${surah.number}_${ayah.number}_${now.microsecondsSinceEpoch}',
      surahName: surah.latinName,
      surahNumber: surah.number,
      verseNumber: ayah.number,
      arabicText: ayah.arabicFor(style ?? MushafStyle.kemenag),
      translation: ayah.translation,
      color: color,
      timestamp: existing?.timestamp ?? now,
    );

    await ref.read(bookmarksProvider.notifier).save(bookmark);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final BookmarkColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected
                ? color.color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BookmarkBadge(color: color, size: 42, selected: selected),
              const SizedBox(height: 8),
              Text(
                color.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
