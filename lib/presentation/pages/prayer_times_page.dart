import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/prayer_utils.dart';
import '../../domain/entities/prayer.dart';
import '../providers/core_providers.dart';
import '../providers/prayer_providers.dart';
import '../widgets/common_views.dart';
import '../widgets/prayer_location_sheet.dart';
import '../widgets/prayer_reminder_settings.dart';

class PrayerTimesPage extends ConsumerWidget {
  const PrayerTimesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(prayerSyncProvider);
    final now = ref.watch(prayerClockProvider).value ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waktu Shalat'),
        actions: [
          IconButton(
            tooltip: 'Pilih lokasi',
            onPressed: () => showPrayerLocationSheet(context),
            icon: const Icon(Icons.edit_location_alt_outlined),
          ),
          IconButton(
            tooltip: 'Hitung ulang waktu shalat',
            onPressed: () => ref.read(prayerSyncProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: scheduleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(prayerSyncProvider.notifier).refresh(),
        ),
        data: (schedule) {
          if (schedule == null) {
            return EmptyState(
              icon: Icons.mosque_outlined,
              title: 'Waktu shalat belum dimuat',
              message:
                  'Pilih lokasi, lalu hitung waktu shalat untuk hari ini dan '
                  'tujuh hari ke depan.',
            );
          }
          return _PrayerTimesBody(schedule: schedule, now: now);
        },
      ),
    );
  }
}

class _PrayerTimesBody extends ConsumerWidget {
  const _PrayerTimesBody({required this.schedule, required this.now});

  final PrayerSchedule schedule;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final next = schedule.nextAfter(now);
    final countdown = schedule.countdownTo(now);
    final isTomorrow =
        next != null &&
        schedule.today.moments.isNotEmpty &&
        next.instant.isAfter(schedule.today.moments.last.instant);

    return RefreshIndicator(
      onRefresh: () => ref.read(prayerSyncProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.mosque_outlined,
                      size: 18,
                      color: theme.colorScheme.onPrimary.withValues(alpha: .8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SHALAT BERIKUTNYA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: .8,
                        ),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (isTomorrow)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: .14,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Besok',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next?.prayer.label ?? '—',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            next == null
                                ? ''
                                : formatPrayerClock(next, schedule.timeZoneId),
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w300,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (next != null)
                      Text(
                        next.prayer.arabicLabel,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 34,
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: .85,
                          ),
                        ),
                      ),
                  ],
                ),
                if (countdown != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${formatCountdown(countdown)} lagi',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => showPrayerLocationSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          schedule.timeZoneId.startsWith('Asia/')
                              ? Icons.place_outlined
                              : Icons.public,
                          size: 16,
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: .8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${schedule.locationLabel} · '
                            '${formatPrayerDate(schedule.today.date)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: .85,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: .7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                for (var index = 0; index < Prayer.values.length; index++) ...[
                  if (index > 0) const Divider(),
                  _PrayerRow(
                    prayer: Prayer.values[index],
                    moment: schedule.today.momentFor(Prayer.values[index]),
                    timeZoneId: schedule.timeZoneId,
                    isNext: next?.prayer == Prayer.values[index],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const PrayerReminderSettings(),
          const SizedBox(height: 18),
          const _WidgetCard(),
          const SizedBox(height: 16),
          Text(
            'Waktu dihitung dengan metode Kemenag: sudut Subuh 20°, Isya 18°, '
            'mazhab Syafi\'i, dan ihtiyati 2 menit. Perhitungan mengikuti '
            'koordinat lokasi yang dipilih; perbedaan 1–2 menit dari jadwal '
            'masjid setempat adalah hal yang wajar.',
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
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.moment,
    required this.timeZoneId,
    required this.isNext,
  });

  final Prayer prayer;
  final PrayerMoment moment;
  final String timeZoneId;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isNext
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: .5,
                    ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _iconFor(prayer),
              size: 21,
              color: isNext
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      prayer.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Berikutnya',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  prayer.arabicLabel,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPrayerClock(moment, timeZoneId),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(Prayer prayer) => switch (prayer) {
    Prayer.fajr => Icons.nights_stay_outlined,
    Prayer.dhuhr => Icons.wb_sunny_outlined,
    Prayer.asr => Icons.wb_twilight_outlined,
    Prayer.maghrib => Icons.wb_twilight,
    Prayer.isha => Icons.dark_mode_outlined,
  };
}

class _WidgetCard extends ConsumerWidget {
  const _WidgetCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final supported = ref.watch(prayerWidgetPinSupportedProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.widgets_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Widget layar utama',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              supported.value == true
                  ? 'Tampilkan waktu shalat berikutnya beserta hitungan '
                        'mundurnya di layar utama.'
                  : 'Widget waktu shalat tersedia di Android. Pasang dari '
                        'daftar widget launcher setelah data diperbarui.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: supported.value == true
                    ? () => _pin(context, ref)
                    : null,
                icon: const Icon(Icons.add_to_home_screen_outlined),
                label: const Text('Pasang widget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pin(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(syncPrayerWidgetProvider).pin();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Widget waktu shalat dipasang.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
