import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/text_utils.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/member_progress.dart';
import '../../domain/entities/reading_group.dart';
import '../../domain/entities/reading_progress.dart';
import '../providers/auth_providers.dart';
import '../providers/challenge_providers.dart';
import '../providers/daily_tilawah_providers.dart';
import '../providers/reading_progress_providers.dart';
import '../widgets/common_views.dart';
import '../widgets/invite_code_card.dart';

class GroupDetailPage extends ConsumerWidget {
  const GroupDetailPage({super.key, required this.groupId, this.initialGroup});

  final String groupId;

  /// Shown while the real-time document is still loading.
  final ReadingGroup? initialGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupAsync = ref.watch(readingGroupProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final user = ref.watch(currentUserProvider);
    final group = groupAsync.value ?? initialGroup;

    if (groupAsync.hasValue && groupAsync.value == null) {
      return Scaffold(
        appBar: AppBar(title: Text(initialGroup?.name ?? 'Grup')),
        body: const EmptyState(
          icon: Icons.group_off_outlined,
          title: 'Grup tidak tersedia',
          message:
              'Grup ini sudah dihapus atau Anda sudah tidak menjadi '
              'anggotanya.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group?.name ?? 'Grup bacaan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (group != null)
              Text(
                '${group.memberCount} anggota',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (group != null && user != null)
            PopupMenuButton<String>(
              tooltip: 'Opsi grup',
              onSelected: (value) =>
                  _onGroupAction(context, ref, value, group, user),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'sync',
                  child: Text('Sinkronkan progres'),
                ),
                PopupMenuItem(
                  value: 'leave',
                  child: Text(
                    group.isOwner(user.uid) ? 'Hapus grup' : 'Keluar grup',
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (group != null)
            InviteCodeCard(code: group.code, memberCount: group.memberCount),
          const SizedBox(height: 12),
          const _MyProgressCard(),
          const SizedBox(height: 22),
          Text(
            'PAPAN PERINGKAT',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          membersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            data: (members) => members.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Belum ada anggota yang membaca. Ajak teman dengan kode '
                      'undangan di atas.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: [
                      for (var index = 0; index < members.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MemberProgressTile(
                            member: members[index],
                            rank: index + 1,
                            isMe: members[index].uid == user?.uid,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            'Peringkat diperbarui otomatis setiap kali anggota membaca halaman '
            'atau ayat baru.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGroupAction(
    BuildContext context,
    WidgetRef ref,
    String value,
    ReadingGroup group,
    AppUser user,
  ) async {
    if (value == 'sync') {
      try {
        await ref.read(readingProgressProvider.notifier).syncNow();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Progres bacaan tersinkron.')),
          );
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return;
    }

    final isOwner = group.isOwner(user.uid);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isOwner ? 'Hapus grup?' : 'Keluar dari grup?'),
        content: Text(
          isOwner
              ? 'Seluruh progres anggota pada grup ini akan dihapus dan kode '
                    'undangan tidak berlaku lagi.'
              : 'Progres Anda tetap tersimpan di perangkat dan bisa dikirim '
                    'lagi saat bergabung ke grup lain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isOwner ? 'Hapus' : 'Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final controller = ref.read(challengeControllerProvider.notifier);
      if (isOwner) {
        await controller.deleteGroup(group.id);
      } else {
        await controller.leaveGroup(group.id);
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _MyProgressCard extends ConsumerStatefulWidget {
  const _MyProgressCard();

  @override
  ConsumerState<_MyProgressCard> createState() => _MyProgressCardState();
}

class _MyProgressCardState extends ConsumerState<_MyProgressCard> {
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = ref.watch(readingProgressProvider);
    final daily = ref.watch(dailyTilawahProvider);
    final dailyComplete = daily.isCompleteFor(progress);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_stories_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    progress == null ? 'Belum ada progres' : progress.reference,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${progress?.percent ?? 0}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress?.ratio ?? 0,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  dailyComplete
                      ? Icons.check_circle_rounded
                      : Icons.menu_book_outlined,
                  size: 16,
                  color: dailyComplete ? scheme.secondary : scheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '1D1J hari ini: '
                    '${formatPageCount(daily.pagesRead(progress))}/'
                    '${daily.targetPages} halaman'
                    '${dailyComplete ? ' • selesai' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress == null
                        ? 'Buka surah untuk mencatat posisi bacaan Anda.'
                        : 'Diperbarui ${_relativeTime(progress.updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _syncing ? null : _sync,
                  icon: _syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 18),
                  label: const Text('Sinkronkan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await ref.read(readingProgressProvider.notifier).syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Progres bacaan tersinkron.')),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

class _MemberProgressTile extends StatelessWidget {
  const _MemberProgressTile({
    required this.member,
    required this.rank,
    required this.isMe,
  });

  final MemberProgress member;
  final int rank;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLeader = rank == 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Anda',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${member.percent}%',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isLeader ? scheme.secondary : scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.progress.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (member.hasDailyTargetToday) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          member.dailyCompleted
                              ? Icons.check_circle_rounded
                              : Icons.menu_book_outlined,
                          size: 13,
                          color: member.dailyCompleted
                              ? scheme.secondary
                              : scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.dailyCompleted
                              ? '1D1J selesai hari ini'
                              : '1D1J ${formatPageCount(member.dailyPages)}/'
                                    '${member.dailyTargetPages} hlm',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: member.dailyCompleted
                                ? scheme.secondary
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: member.ratio,
                      minHeight: 6,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: isLeader ? scheme.secondary : scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatNumber(member.versesRead)} / '
                    '${_formatNumber(totalQuranVerses)} ayat',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highlight = rank <= 3;

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: highlight ? scheme.onSecondaryContainer : scheme.onSurface,
        ),
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final delta = DateTime.now().difference(time);
  if (delta.inSeconds < 60) return 'baru saja';
  if (delta.inMinutes < 60) return '${delta.inMinutes} menit lalu';
  if (delta.inHours < 24) return '${delta.inHours} jam lalu';
  return '${delta.inDays} hari lalu';
}

/// 1234 -> 1.234
String _formatNumber(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
