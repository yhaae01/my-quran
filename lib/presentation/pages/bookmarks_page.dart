import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/bookmark_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/bookmark_badge.dart';
import '../widgets/common_views.dart';
import '../widgets/reading_mode_sheet.dart';

class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({super.key});

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage> {
  BookmarkColor? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final bookmarks = bookmarksAsync.value ?? const <Bookmark>[];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Penanda Ayat'),
            if (bookmarks.isNotEmpty)
              Text(
                '${bookmarks.length} penanda tersimpan',
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
                  'Pilih warna merah, hijau, kuning, atau biru untuk '
                  'mengelompokkan bacaan Anda.',
            );
          }
          return _BookmarksBody(
            bookmarks: all,
            filter: _filter,
            onFilterChanged: (color) => setState(() => _filter = color),
          );
        },
      ),
    );
  }
}

class _BookmarksBody extends ConsumerWidget {
  const _BookmarksBody({
    required this.bookmarks,
    required this.filter,
    required this.onFilterChanged,
  });

  final List<Bookmark> bookmarks;
  final BookmarkColor? filter;
  final ValueChanged<BookmarkColor?> onFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = <BookmarkColor, int>{
      for (final color in BookmarkColor.values)
        color: bookmarks.where((bookmark) => bookmark.color == color).length,
    };

    final children = <Widget>[];
    for (final color in BookmarkColor.values) {
      if (filter != null && filter != color) continue;
      final items = bookmarks
          .where((bookmark) => bookmark.color == color)
          .toList();
      if (items.isEmpty) continue;

      children.add(_GroupHeader(color: color, count: items.length));
      for (final bookmark in items) {
        children.add(_BookmarkCard(bookmark: bookmark));
      }
    }

    return Column(
      children: [
        _FilterBar(
          counts: counts,
          selected: filter,
          onChanged: onFilterChanged,
        ),
        Expanded(
          child: children.isEmpty
              ? EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title:
                      'Tidak ada penanda ${filter?.label.toLowerCase() ?? ''}',
                  message:
                      'Penanda dengan warna ini belum ada. Pilih warna lain '
                      'atau tambahkan penanda baru dari halaman surah.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  children: children,
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  final Map<BookmarkColor, int> counts;
  final BookmarkColor? selected;
  final ValueChanged<BookmarkColor?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ChoiceChip(
            label: Text('Semua (${counts.values.fold(0, (a, b) => a + b)})'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final color in BookmarkColor.values)
            ChoiceChip(
              avatar: BookmarkBadge(color: color, size: 14, showShadow: false),
              label: Text('${color.label} (${counts[color] ?? 0})'),
              selected: selected == color,
              onSelected: (_) => onChanged(selected == color ? null : color),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.color, required this.count});

  final BookmarkColor color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
      child: Row(
        children: [
          BookmarkBadge(color: color, size: 17),
          const SizedBox(width: 10),
          Text(
            color.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: color.color.withValues(alpha: 0.28),
              indent: 2,
              endIndent: 4,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count ayat',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorTag extends StatelessWidget {
  const _ColorTag({required this.color});

  final BookmarkColor color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 10, 3),
      decoration: BoxDecoration(
        color: color.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BookmarkBadge(color: color, size: 11, showShadow: false),
          const SizedBox(width: 6),
          Text(
            color.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryTag extends StatelessWidget {
  const _PrimaryTag();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 10, 3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_added, size: 12, color: scheme.primary),
          const SizedBox(width: 5),
          Text(
            'Lanjutkan Bacaan',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
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
    final pinned = ref.watch(continueReadingBookmarkProvider);
    final isPrimary = pinned?.id == bookmark.id;
    final arabic = bookmark.arabicSnippet;
    final translation = bookmark.translation.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(bookmark.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ),
        onDismissed: (_) => _remove(context, ref),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openReader(context, ref),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bookmark.color.color.withValues(alpha: 0.09),
                    scheme.surfaceContainerLow,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        BookmarkBadge(color: bookmark.color, size: 19),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bookmark.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Opsi lanjutkan bacaan',
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'continue',
                              child: Text(
                                isPrimary
                                    ? 'Batalkan lanjutkan bacaan'
                                    : 'Jadikan Lanjutkan Bacaan',
                              ),
                            ),
                          ],
                          onSelected: (_) =>
                              _toggleContinueReading(context, ref, isPrimary),
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
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          _ColorTag(color: bookmark.color),
                          if (isPrimary) ...[
                            const SizedBox(width: 6),
                            const _PrimaryTag(),
                          ],
                          const Spacer(),
                          Icon(
                            Icons.schedule,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              bookmark.hasTimestamp
                                  ? formatDateTimeLabel(bookmark.timestamp)
                                  : 'Tanggal tidak tercatat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (arabic.isNotEmpty)
                      Text(
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

    // Let the reader choose between per-ayah and mushaf views instead of
    // always landing on the Ayah list.
    unawaited(
      openVerseInReadingMode(
        context,
        ref,
        surahNumber: bookmark.surahNumber,
        verseNumber: bookmark.verseNumber,
        surahName: bookmark.displaySurahName,
        // Opening a saved reference must not advance the reading challenge;
        // progress only follows the reader's active position.
        reportInitialAyah: false,
      ),
    );
  }

  /// Promotes this bookmark to the single "Lanjutkan Bacaan" reference, which
  /// also pushes its verse to the group challenge, or releases it again.
  Future<void> _toggleContinueReading(
    BuildContext context,
    WidgetRef ref,
    bool isPrimary,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(bookmarksProvider.notifier);
    if (isPrimary) {
      await notifier.clearContinueReading();
    } else {
      await notifier.setContinueReading(bookmark);
    }
    if (!messenger.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isPrimary
                ? 'Penanda utama dilepas. Progres mengikuti bacaan terakhir.'
                : '${bookmark.title} dijadikan Lanjutkan Bacaan.',
          ),
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
