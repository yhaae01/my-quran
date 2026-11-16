import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/hijri_utils.dart';
import '../../core/utils/prayer_utils.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/reading_progress.dart';
import '../providers/bookmark_providers.dart';
import '../providers/core_providers.dart';
import '../providers/reading_progress_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/reading_mode_sheet.dart';
import 'challenge_page.dart';
import 'hijri_calendar_page.dart';
import 'mushaf_reader_page.dart';
import 'settings_page.dart';
import 'surah_list_page.dart';
import 'surah_reader_page.dart';

/// Home dashboard: the visitor picks a reading mode or a companion feature
/// before entering the distraction-free reader screens.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    super.key,
    required this.onOpenMushaf,
    required this.onOpenPrayerTimes,
    required this.onOpenBookmarks,
  });

  final VoidCallback onOpenMushaf;
  final VoidCallback onOpenPrayerTimes;
  final VoidCallback onOpenBookmarks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(readingProgressProvider);
    final bookmarks = ref.watch(bookmarksProvider).value ?? const <Bookmark>[];
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Assalamu'alaikum",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Al-Qur'an • 604 halaman • 30 juz",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Kalender Hijriah',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const HijriCalendarPage(),
              ),
            ),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _HijriCalendarCard(now: now),
          const SizedBox(height: 14),
          _ContinueReadingCard(
            progress: progress,
            onTap: () => _openReader(context, ref, progress),
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Baca per Ayat',
                    subtitle: 'Arab & terjemahan',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SurahListPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.auto_stories_outlined,
                    title: 'Mushaf',
                    subtitle: '604 halaman',
                    onTap: onOpenMushaf,
                  ),
                ),
              ],
            ),
          ),
          const _SectionHeader('Jelajahi'),
          Card(
            child: Column(
              children: [
                _FeatureTile(
                  icon: Icons.mosque_outlined,
                  title: 'Waktu Shalat',
                  subtitle: 'Jadwal, pengingat, dan widget',
                  onTap: onOpenPrayerTimes,
                ),
                const Divider(),
                _FeatureTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Kalender Hijriah',
                  subtitle:
                      'Kalender bulanan, konversi masehi, dan puasa sunnah',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HijriCalendarPage(),
                    ),
                  ),
                ),
                const Divider(),
                _FeatureTile(
                  icon: Icons.groups_outlined,
                  title: 'Tantangan Kelompok',
                  subtitle: 'Baca bersama teman dan lihat progres',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChallengePage(),
                    ),
                  ),
                ),
                const Divider(),
                _FeatureTile(
                  icon: Icons.bookmarks_outlined,
                  title: 'Penanda Ayat',
                  subtitle: bookmarks.isEmpty
                      ? 'Belum ada penanda tersimpan'
                      : '${bookmarks.length} penanda tersimpan',
                  onTap: onOpenBookmarks,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Pilih salah satu mode baca. Di dalam reader, putar layar ke '
            'landscape atau tekan ikon layar penuh untuk mode baca tanpa '
            'gangguan.',
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

  /// Asks for the preferred reading mode before continuing, so the reader is
  /// never dropped into Ayah mode without a choice.
  Future<void> _openReader(
    BuildContext context,
    WidgetRef ref,
    ReadingProgress? progress,
  ) async {
    final mode = await showReadingModeSheet(
      context,
      title: progress == null ? 'Mulai membaca' : 'Lanjutkan bacaan',
      subtitle: progress == null
          ? null
          : '${progress.surahName} • Ayat ${progress.ayahNumber}',
    );
    if (mode == null || !context.mounted) return;

    if (mode == ReadingMode.mushaf) {
      final page = progress == null
          ? 1
          : await ref.read(locateMushafPageProvider)(
              ref.read(settingsProvider).mushafStyle,
              surah: progress.surahNumber,
              ayah: progress.ayahNumber,
            );
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MushafReaderPage(initialPage: page),
        ),
      );
      return;
    }

    if (progress == null) {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SurahListPage()));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SurahReaderPage(
          surahNumber: progress.surahNumber,
          initialSurahName: progress.surahName,
          initialVerseNumber: progress.ayahNumber,
          backToSurahList: true,
        ),
      ),
    );
  }
}

/// Today's Hijri date, shown beside the Gregorian date at the top of Beranda.
/// Tapping the card opens the full interactive monthly Hijri calendar.
class _HijriCalendarCard extends StatelessWidget {
  const _HijriCalendarCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hijri = HijriDay.fromDate(now);

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HijriCalendarPage()),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: scheme.secondary.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.nightlight_outlined,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KALENDER HIJRIAH',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hijri.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      formatPrayerDate(now),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.progress, required this.onTap});

  final ReadingProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = progress;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      current == null ? 'Mulai membaca' : 'Lanjutkan bacaan',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: scheme.primary),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                current == null ? 'Al-Fatihah' : current.surahName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                current == null
                    ? 'Buka surah pertama untuk memulai perjalanan Anda.'
                    : 'Ayat ${current.ayahNumber} • '
                          '${current.percent}% Al-Qur\'an',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: current?.ratio ?? 0,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
