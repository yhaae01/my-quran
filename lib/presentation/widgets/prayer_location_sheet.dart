import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/prayer_city.dart';
import '../../domain/entities/prayer_preferences.dart';
import '../providers/core_providers.dart';
import '../providers/settings_providers.dart';

Future<void> showPrayerLocationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _PrayerLocationSheet(),
  );
}

class _PrayerLocationSheet extends ConsumerStatefulWidget {
  const _PrayerLocationSheet();

  @override
  ConsumerState<_PrayerLocationSheet> createState() =>
      _PrayerLocationSheetState();
}

class _PrayerLocationSheetState extends ConsumerState<_PrayerLocationSheet> {
  final TextEditingController _search = TextEditingController();
  bool _detecting = false;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prayer = ref.watch(settingsProvider.select((item) => item.prayer));
    final cities = indonesianPrayerCities.where((city) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return city.name.toLowerCase().contains(query) ||
          city.province.toLowerCase().contains(query);
    }).toList();

    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lokasi waktu shalat',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: _detecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Icon(Icons.my_location),
                title: const Text('Gunakan lokasi saat ini'),
                subtitle: Text(
                  prayer.locationMode == PrayerLocationMode.automatic &&
                          prayer.hasAutomaticFix
                      ? '${prayer.resolvedLocationLabel} — '
                            '${prayer.resolvedTimeZoneId}'
                      : 'Membaca GPS dan zona waktu perangkat.',
                ),
                trailing:
                    prayer.locationMode == PrayerLocationMode.automatic &&
                        prayer.hasAutomaticFix
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: _detecting ? null : _detectLocation,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Cari kota atau provinsi',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text(
                  'KOTA PILIHAN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: cities.isEmpty
                    ? Center(
                        child: Text(
                          'Kota tidak ditemukan',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: cities.length,
                        itemBuilder: (context, index) {
                          final city = cities[index];
                          final selected =
                              prayer.locationMode == PrayerLocationMode.city &&
                              prayer.cityId == city.id;
                          return ListTile(
                            leading: Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(city.name),
                            subtitle: Text(
                              '${city.province} · ${city.timeZoneLabel}',
                            ),
                            selected: selected,
                            onTap: () {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setPrayerCity(city.id);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() => _detecting = true);
    try {
      final location = await ref.read(detectCurrentLocationProvider)();
      ref.read(settingsProvider.notifier).setDevicePrayerLocation(location);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }
}
