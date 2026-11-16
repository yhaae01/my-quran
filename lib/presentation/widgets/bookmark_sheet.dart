import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ayah.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/mushaf.dart';
import '../../domain/entities/surah.dart';
import '../providers/bookmark_providers.dart';

Future<void> showBookmarkSheet(
  BuildContext context, {
  required Surah surah,
  required Ayah ayah,
  Bookmark? existing,
  MushafStyle? style,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BookmarkSheet(
      surah: surah,
      ayah: ayah,
      existing: existing,
      style: style,
    ),
  );
}

/// Saves the tapped verse as the single active bookmark.
///
/// There are no colour categories any more: the saved verse is simply the last
/// marker and the "Lanjutkan Bacaan" position, which is why the sheet explains
/// that a new marker replaces the previous one.
class BookmarkSheet extends ConsumerWidget {
  const BookmarkSheet({
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
    final scheme = theme.colorScheme;
    final isSaved = existing != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bookmark_rounded, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSaved ? Bookmark.savedLabel : 'Tandai ayat',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${surah.latinName} • Ayat ${ayah.number}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
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
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ayah.translation,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _save(context, ref),
              icon: const Icon(Icons.bookmark_add_rounded),
              label: Text(
                isSaved
                    ? 'Perbarui ${Bookmark.activeLabel}'
                    : 'Simpan sebagai ${Bookmark.activeLabel}',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Hanya satu penanda aktif. Ayat ini menggantikan penanda '
              'sebelumnya dan menjadi titik Lanjutkan Bacaan yang ikut '
              'menyinkronkan progres tantangan kelompok Anda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (isSaved) ...[
              const SizedBox(height: 14),
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

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final bookmark = Bookmark(
      id: '${surah.number}_${ayah.number}',
      surahName: surah.latinName,
      surahNumber: surah.number,
      verseNumber: ayah.number,
      arabicText: ayah.arabicFor(style ?? MushafStyle.kemenag),
      translation: ayah.translation,
      timestamp: now,
    );

    await ref.read(bookmarksProvider.notifier).save(bookmark);
    if (context.mounted) Navigator.of(context).pop();
  }
}
