import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_preferences.dart';
import '../providers/core_providers.dart';
import '../providers/settings_providers.dart';

/// Notification switch plus per-prayer selection. Used by both the prayer
/// screen and Settings so the two stay in sync through [settingsProvider].
class PrayerReminderSettings extends ConsumerWidget {
  const PrayerReminderSettings({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prayer = ref.watch(settingsProvider.select((item) => item.prayer));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            secondary: Icon(
              prayer.notificationsEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_outlined,
            ),
            title: const Text('Pengingat adzan'),
            subtitle: Text(
              prayer.notificationsEnabled
                  ? 'Notifikasi dijadwalkan untuk ${_summary(prayer)}.'
                  : 'Dapatkan notifikasi saat waktu shalat tiba.',
            ),
            value: prayer.notificationsEnabled,
            onChanged: (value) => _toggleNotifications(context, ref, value),
          ),
          if (prayer.notificationsEnabled) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                'Waktu shalat yang diingatkan',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final item in Prayer.values)
                    FilterChip(
                      label: Text(item.label),
                      selected: prayer.enabledPrayers.contains(item),
                      onSelected: (selected) => ref
                          .read(settingsProvider.notifier)
                          .setPrayerEnabled(item, selected),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Pengingat dijadwalkan ulang setiap aplikasi dibuka. '
                'Jika mode hemat daya menunda notifikasi, buka pengaturan '
                'baterai dan izinkan aktivitas latar belakang.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    if (value) {
      try {
        final granted = await ref.read(
          requestPrayerNotificationPermissionProvider,
        )();
        if (!context.mounted) return;
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin notifikasi belum diberikan. Aktifkan dari pengaturan '
                'sistem agar pengingat adzan bisa muncul.',
              ),
            ),
          );
          return;
        }
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
        return;
      }
    }
    ref.read(settingsProvider.notifier).setPrayerNotificationsEnabled(value);
  }

  String _summary(PrayerPreferences preferences) {
    if (preferences.enabledPrayers.isEmpty) return 'belum ada waktu dipilih';
    return Prayer.values
        .where(preferences.enabledPrayers.contains)
        .map((prayer) => prayer.label)
        .join(', ');
  }
}
