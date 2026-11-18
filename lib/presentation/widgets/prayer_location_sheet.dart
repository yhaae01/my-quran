import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/detected_location.dart';
import '../../domain/entities/prayer_preferences.dart';
import '../../domain/entities/prayer_region.dart';
import '../../domain/repositories/region_repository.dart';
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

  String _query = '';
  bool _detecting = false;
  bool _loading = true;
  bool _searching = false;
  String? _error;

  List<PrayerProvince> _provinces = const [];
  PrayerProvince? _province;
  List<PrayerRegency> _regencies = const [];
  PrayerRegency? _regency;
  List<PrayerDistrict> _districts = const [];
  PrayerDistrict? _district;
  List<PrayerVillage> _villages = const [];
  List<PrayerRegionMatch> _results = const [];
  int _searchGeneration = 0;

  RegionRepository get _regions => ref.read(regionRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provinces = await _regions.provinces();
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Data wilayah tidak bisa dimuat: $error';
        _loading = false;
      });
    }
  }

  Future<void> _openProvince(PrayerProvince province) async {
    setState(() {
      _province = province;
      _regencies = const [];
      _regency = null;
      _districts = const [];
      _district = null;
      _villages = const [];
      _loading = true;
      _error = null;
    });
    try {
      final regencies = await _regions.regenciesOf(province.id);
      if (!mounted) return;
      setState(() {
        _regencies = regencies;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Kabupaten/kota tidak bisa dimuat: $error';
        _loading = false;
      });
    }
  }

  Future<void> _openRegency(PrayerRegency regency) async {
    setState(() {
      _regency = regency;
      _districts = const [];
      _district = null;
      _villages = const [];
      _loading = true;
      _error = null;
    });
    try {
      final districts = await _regions.districtsOf(regency.id);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Kecamatan tidak bisa dimuat: $error';
        _loading = false;
      });
    }
  }

  Future<void> _openDistrict(PrayerDistrict district) async {
    setState(() {
      _district = district;
      _villages = const [];
      _loading = true;
      _error = null;
    });
    try {
      final villages = await _regions.villagesOf(district.id);
      if (!mounted) return;
      setState(() {
        _villages = villages;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Desa/kelurahan tidak bisa dimuat: $error';
        _loading = false;
      });
    }
  }

  void _goBack() {
    setState(() {
      _error = null;
      if (_district != null) {
        _district = null;
        _villages = const [];
      } else if (_regency != null) {
        _regency = null;
        _districts = const [];
      } else if (_province != null) {
        _province = null;
        _regencies = const [];
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    final generation = ++_searchGeneration;
    setState(() {
      _query = value;
      _error = null;
      if (query.isEmpty) {
        _results = const [];
        _searching = false;
      } else {
        _searching = true;
      }
    });
    if (query.isEmpty) return;

    Future<void>.delayed(const Duration(milliseconds: 180), () async {
      if (!mounted || generation != _searchGeneration) return;
      try {
        final results = await _regions.search(query);
        if (!mounted || generation != _searchGeneration) return;
        setState(() {
          _results = results;
          _searching = false;
        });
      } catch (error) {
        if (!mounted || generation != _searchGeneration) return;
        setState(() {
          _results = const [];
          _searching = false;
          _error = 'Pencarian gagal: $error';
        });
      }
    });
  }

  void _retry() {
    if (_query.trim().isNotEmpty) {
      _onSearchChanged(_query);
    } else if (_district != null) {
      _openDistrict(_district!);
    } else if (_regency != null) {
      _openRegency(_regency!);
    } else if (_province != null) {
      _openProvince(_province!);
    } else {
      _loadProvinces();
    }
  }

  void _select(PrayerRegionMatch match) {
    ref.read(settingsProvider.notifier).setPrayerRegion(match);
    Navigator.of(context).pop();
  }

  void _selectDistrict(PrayerDistrict district) {
    final province = _province;
    final regency = _regency;
    if (province == null || regency == null) return;
    _select(
      PrayerRegionMatch(
        province: province,
        regency: regency,
        district: district,
      ),
    );
  }

  void _selectVillage(PrayerVillage village) {
    final province = _province;
    final regency = _regency;
    final district = _district;
    if (province == null || regency == null || district == null) return;
    _select(
      PrayerRegionMatch(
        province: province,
        regency: regency,
        district: district,
        village: village,
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() => _detecting = true);
    try {
      final location = await ref.read(detectCurrentLocationProvider)();
      var label =
          '${location.label} '
          '(${location.latitude.toStringAsFixed(3)}, '
          '${location.longitude.toStringAsFixed(3)})';
      var timeZoneId = location.timeZoneId;
      try {
        final match = await _regions.nearest(
          latitude: location.latitude,
          longitude: location.longitude,
        );
        if (match != null) {
          label = '${match.label} (GPS)';
          timeZoneId = match.timeZoneId;
        }
      } catch (error) {
        debugPrint('Kecamatan terdekat tidak ditemukan: $error');
      }
      ref
          .read(settingsProvider.notifier)
          .setDevicePrayerLocation(
            DetectedLocation(
              latitude: location.latitude,
              longitude: location.longitude,
              timeZoneId: timeZoneId,
              label: label,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prayer = ref.watch(settingsProvider.select((item) => item.prayer));
    final hasSelection =
        prayer.locationMode == PrayerLocationMode.city && prayer.hasRegion;
    final selectedRegionId = prayer.regionId;

    return FractionallySizedBox(
      heightFactor: 0.9,
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
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: _nested ? 'Kembali' : 'Tutup',
                      onPressed: _goBack,
                      icon: Icon(_nested ? Icons.arrow_back : Icons.close),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi waktu shalat',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_nested)
                            Text(
                              _breadcrumb,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_query.trim().isEmpty) ...[
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
                        ? '${prayer.resolvedLocationLabel} · '
                              '${prayerTimeZoneLabel(prayer.resolvedTimeZoneId)}'
                        : 'Membaca GPS lalu mencocokkan kecamatan terdekat.',
                  ),
                  trailing:
                      prayer.locationMode == PrayerLocationMode.automatic &&
                          prayer.hasAutomaticFix
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: _detecting ? null : _detectLocation,
                ),
                const Divider(),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari kecamatan, kabupaten, atau provinsi',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _search.clear();
                              _searchGeneration++;
                              setState(() {
                                _query = '';
                                _results = const [];
                                _searching = false;
                              });
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: _buildBody(
                  theme,
                  hasSelection: hasSelection,
                  selectedRegionId: selectedRegionId,
                  selectedVillageId: prayer.villageId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _nested =>
      _province != null || _regency != null || _district != null;

  String get _breadcrumb {
    final parts = <String>[
      if (_province != null) _province!.name,
      if (_regency != null) _regency!.name,
      if (_district != null) _district!.name,
    ];
    return parts.join(' › ');
  }

  Widget _buildBody(
    ThemeData theme, {
    required bool hasSelection,
    required String? selectedRegionId,
    required String? selectedVillageId,
  }) {
    if (_loading || _searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _retry, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }
    if (_query.trim().isNotEmpty) {
      return _buildSearchResults(theme);
    }
    if (_district != null) {
      return _buildVillages(
        theme,
        hasSelection: hasSelection,
        selectedRegionId: selectedRegionId,
        selectedVillageId: selectedVillageId,
      );
    }
    if (_regency != null) {
      return _buildDistricts(theme, selectedRegionId);
    }
    if (_province != null) {
      return _buildRegencies(theme, selectedRegionId);
    }
    return _buildProvinces(theme, selectedRegionId);
  }

  Widget _buildProvinces(ThemeData theme, String? selectedRegionId) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _provinces.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SectionLabel('PILIH PROVINSI', theme: theme);
        }
        final province = _provinces[index - 1];
        final selected = selectedRegionId?.startsWith(province.id) ?? false;
        return ListTile(
          leading: Icon(
            selected ? Icons.radio_button_checked : Icons.map_outlined,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(province.name),
          subtitle: Text(province.timeZoneLabel),
          trailing: const Icon(Icons.chevron_right),
          selected: selected,
          onTap: () => _openProvince(province),
        );
      },
    );
  }

  Widget _buildRegencies(ThemeData theme, String? selectedRegionId) {
    if (_regencies.isEmpty) {
      return const _EmptyList('Kabupaten/kota tidak ditemukan.');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _regencies.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SectionLabel('KABUPATEN / KOTA', theme: theme);
        }
        final regency = _regencies[index - 1];
        final selected = selectedRegionId?.startsWith(regency.id) ?? false;
        return ListTile(
          leading: Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(regency.name),
          subtitle: Text(regency.timeZoneLabel),
          trailing: const Icon(Icons.chevron_right),
          selected: selected,
          onTap: () => _openRegency(regency),
        );
      },
    );
  }

  Widget _buildDistricts(ThemeData theme, String? selectedRegionId) {
    if (_districts.isEmpty) {
      return const _EmptyList('Kecamatan tidak ditemukan.');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _districts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SectionLabel(
            'KECAMATAN · ${_districts.length}',
            theme: theme,
          );
        }
        final district = _districts[index - 1];
        final selected = selectedRegionId == district.id;
        return ListTile(
          leading: Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(district.name),
          subtitle: const Text('Pilih desa/kelurahan →'),
          selected: selected,
          onTap: () => _openDistrict(district),
        );
      },
    );
  }

  Widget _buildVillages(
    ThemeData theme, {
    required bool hasSelection,
    required String? selectedRegionId,
    required String? selectedVillageId,
  }) {
    final district = _district!;
    final districtSelected = hasSelection && selectedRegionId == district.id;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _villages.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SectionLabel(
            'DESA / KELURAHAN · ${_villages.length}',
            theme: theme,
          );
        }
        if (index == 1) {
          return ListTile(
            leading: Icon(
              districtSelected && selectedVillageId == null
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: districtSelected && selectedVillageId == null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text('Kec. ${district.name}'),
            subtitle: const Text('Gunakan titik pusat kecamatan'),
            selected: districtSelected && selectedVillageId == null,
            onTap: () => _selectDistrict(district),
          );
        }
        final village = _villages[index - 2];
        final selected = hasSelection && selectedVillageId == village.id;
        return ListTile(
          leading: Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(village.name),
          selected: selected,
          onTap: () => _selectVillage(village),
        );
      },
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_results.isEmpty) {
      return _EmptyList('Tidak ada kecamatan yang cocok dengan "$_query".');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SectionLabel(
            'HASIL PENCARIAN · ${_results.length}',
            theme: theme,
          );
        }
        final match = _results[index - 1];
        return ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(match.district.name),
          subtitle: Text('${match.regency.name} · ${match.province.name}'),
          trailing: Text(
            match.timeZoneLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => _select(match),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
