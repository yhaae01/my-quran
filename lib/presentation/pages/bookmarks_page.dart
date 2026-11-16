import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/text_utils.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/bookmark_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/common_views.dart';
import '../widgets/reading_mode_sheet.dart';

/// Shows the single active bookmark, which is also the "Lanjutkan Bacaan"
/// position synced to the group challenge.
class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Penanda Ayat'),
            Text(
              bookmarksAsync.value?.isNotEmpty ?? false
                  ? 'Penanda terakhir • Lanjutkan Bacaan'
                  : 'Belum ada penanda tersimpan',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(bookmarksProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Belum ada penanda',
              message:
                  'Buka sebuah surah, lalu tekan ikon penanda pada ayat. '
                  'Penanda terakhir akan muncul di sini dan menjadi titik '
                  'Lanjutkan Bacaan Anda.',
            );
          }
          return _BookmarkView(bookmark: all.first);
        },
      ),
    );
  }
}

class _BookmarkView extends ConsumerWidget {
  const _BookmarkView({required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.bookmark_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hanya satu penanda aktif. Menandai ayat baru akan '
                  'menggantikan penanda ini dan menyinkronkan progres '
                  'tantangan kelompok Anda.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        _BookmarkCard(bookmark: bookmark),
      ],
    );
  }
}

class _BookmarkCard extends ConsumerWidget {
  const _BookmarkCard({required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = ref.watch(
      settingsProvider.select((settings) => settings.mushafStyle),
    );
    final arabic = bookmark.arabicSnippet;
    final translation = bookmark.translation.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openReader(context, ref),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer.withValues(alpha: 0.28),
                scheme.surfaceContainerLow,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bookmark_rounded,
                        size: 22,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookmark.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            bookmark.hasTimestamp
                                ? formatDateTimeLabel(bookmark.timestamp)
                                : 'Tanggal tidak tercatat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus penanda',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _remove(context, ref),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 11, 4),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_added_rounded,
                            size: 13,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            Bookmark.activeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.touch_app_outlined,
                      size: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Mode per Ayat / Mushaf',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (arabic.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      arabic,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: style.fontFamily,
                        fontSize: 23,
                        height: 1.7,
                        color: scheme.onSurface,
                      ),
                    ),
                  )
                else
                  Text(
                    'Teks Arab tidak tersedia.',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (translation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      translation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openReader(BuildContext context, WidgetRef ref) {
    if (!bookmark.isNavigable) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Penanda ini tidak memiliki nomor surah/ayat yang valid.',
            ),
          ),
        );
      return;
    }

    // The reader picks between per-ayah and mushaf views; opening the marker
    // does not advance the challenge, saving it already did.
    unawaited(
      openVerseInReadingMode(
        context,
        ref,
        surahNumber: bookmark.surahNumber,
        verseNumber: bookmark.verseNumber,
        surahName: bookmark.displaySurahName,
        reportInitialAyah: false,
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    // Capture the messenger before the card is removed from the tree so the
    // undo snackbar is still shown after the provider reloads.
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(bookmarksProvider.notifier).remove(bookmark.id);
    if (!messenger.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Penanda ${bookmark.reference} dihapus.'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () {
              ref.read(bookmarksProvider.notifier).save(bookmark);
            },
          ),
        ),
      );
  }
}
