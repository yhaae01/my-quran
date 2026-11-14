import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_providers.dart';
import '../widgets/mushaf_style_sheet.dart';
import '../widgets/quran_text.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final style = settings.mushafStyle;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _SectionTitle('Tema'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Mode tampilan', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Terang, gelap, atau mengikuti pengaturan perangkat.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<AppThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: AppThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Terang'),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Gelap'),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('Sistem'),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) => ref
                        .read(settingsProvider.notifier)
                        .setThemeMode(selection.first),
                  ),
                ],
              ),
            ),
          ),
          const _SectionTitle('Tampilan'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Gaya mushaf'),
                  subtitle: Text(style.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showMushafStyleSheet(context),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_size),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Ukuran teks Arab',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Text(
                            '${settings.arabicFontSize.round()} pt',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.arabicFontSize,
                        min: AppSettings.minArabicFontSize,
                        max: AppSettings.maxArabicFontSize,
                        divisions:
                            (AppSettings.maxArabicFontSize -
                                    AppSettings.minArabicFontSize)
                                .round(),
                        label: '${settings.arabicFontSize.round()} pt',
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setArabicFontSize(value),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          basmalahFor(style),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: style.fontFamily,
                            fontSize: settings.arabicFontSize,
                            height: 1.8,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _SectionTitle('Penyimpanan & data'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text('Teks & terjemahan'),
                  subtitle: Text('equran.id — Kemenag'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.auto_stories_outlined),
                  title: Text('Teks Uthmani Madinah'),
                  subtitle: Text('quran.com'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.offline_bolt_outlined),
                  title: Text('Penyimpanan lokal'),
                  subtitle: Text('Hive — penanda & cache bacaan offline'),
                ),
              ],
            ),
          ),
          const _SectionTitle('Tentang'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.menu_book_outlined),
                  title: Text("Al-Qur'an"),
                  subtitle: Text('Versi 1.0.0'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Mushaf'),
                  subtitle: Text(
                    '604 halaman untuk Mushaf Madinah dan Mushaf Standar '
                    'Indonesia (Kemenag).',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.font_download_outlined),
                  title: const Text('Font Arab'),
                  subtitle: const Text(
                    'Amiri Quran & Scheherazade New (SIL Open Font License)',
                  ),
                  trailing: Icon(
                    Icons.code,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Teks Arab dan terjemahan dimuat dari jaringan saat pertama kali '
            'dibuka, lalu disimpan di perangkat untuk dibaca kembali secara '
            'offline.',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
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
