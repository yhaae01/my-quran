import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/surah.dart';
import '../providers/bookmark_providers.dart';

Future<void> showBookmarkColorSheet(
  BuildContext context, {
  required Surah surah,
  required Ayah ayah,
  Bookmark? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) =>
        BookmarkColorSheet(surah: surah, ayah: ayah, existing: existing),
  );
}

class BookmarkColorSheet extends ConsumerWidget {
  const BookmarkColorSheet({
    super.key,
    required this.surah,
    required this.ayah,
    this.existing,
  });

  final Surah surah;
  final Ayah ayah;
  final Bookmark? existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existing == null ? 'Tandai ayat' : 'Ubah warna penanda',
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
            const SizedBox(height: 22),
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
            const SizedBox(height: 18),
            Text(
              'Penanda akan tersimpan di perangkat dan bisa dibuka kembali '
              'kapan saja dari halaman Penanda.',
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
      arabicText: ayah.arabic,
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
      borderRadius: BorderRadius.circular(40),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.onSurface : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: selected
                  ? Icon(Icons.check, color: color.onColor, size: 26)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(color.label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
