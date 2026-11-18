import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/text_utils.dart';
import '../providers/daily_tilawah_providers.dart';
import '../providers/reading_progress_providers.dart';

/// Dashboard card for the daily "1 Hari 1 Juz" tilawah target.
///
/// Progress follows the reader's actual position, can be topped up by hand, and
/// completion is pushed to every joined reading group.
class DailyTilawahCard extends ConsumerWidget {
  const DailyTilawahCard({super.key, required this.onOpenReader});

  final VoidCallback onOpenReader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final daily = ref.watch(dailyTilawahProvider);
    final progress = ref.watch(readingProgressProvider);
    final complete = daily.isCompleteFor(progress);
    final percent = daily.percentFor(progress);
    final pages = daily.pagesRead(progress);
    final remaining = daily.remainingPages(progress);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenReader,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primaryContainer,
                          scheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: scheme.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '1D1J',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1 Hari 1 Juz',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Target hari ini • ${daily.targetLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percent%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: complete ? scheme.secondary : scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: daily.ratioFor(progress),
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: complete ? scheme.secondary : scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatPageCount(pages)} dari '
                      '${daily.targetPages} halaman',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    complete
                        ? 'Target tercapai'
                        : 'Sisa ${formatPageCount(remaining)} hlm',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: complete ? scheme.secondary : scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (complete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: scheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Target 1D1J hari ini selesai',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addPage(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('+1 halaman'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _complete(context, ref),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Tandai selesai'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ketuk kartu untuk melanjutkan target hari ini',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPage(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(dailyTilawahProvider.notifier).addManualPage();
    } catch (error) {
      if (!context.mounted) return;
      _showSyncMessage(context, 'Halaman ditambahkan, tetapi ', error);
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(dailyTilawahProvider.notifier).markCompleted();
    } catch (error) {
      if (!context.mounted) return;
      _showSyncMessage(context, 'Target ditandai selesai, tetapi ', error);
    }
  }

  void _showSyncMessage(BuildContext context, String prefix, Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${prefix}grup belum tersinkron: $error')),
      );
  }
}
