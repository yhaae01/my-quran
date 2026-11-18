import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/prayer_region.dart';

/// All regions at province, regency and district level, indexed for fast
/// browsing and search.
class IndonesiaRegionCatalog {
  const IndonesiaRegionCatalog({
    required this.provinces,
    required this.provincesById,
    required this.regenciesByProvince,
    required this.regenciesById,
    required this.districtsByRegency,
    required this.districtsById,
  });

  final List<PrayerProvince> provinces;
  final Map<String, PrayerProvince> provincesById;
  final Map<String, List<PrayerRegency>> regenciesByProvince;
  final Map<String, PrayerRegency> regenciesById;
  final Map<String, List<PrayerDistrict>> districtsByRegency;
  final Map<String, PrayerDistrict> districtsById;
}

/// Loads the bundled administrative region data.
///
/// Provinces, regencies and districts come from a single compact asset. Village
/// lists are split per province and only decoded when the user opens a
/// kecamatan, so the 80k+ villages never cost startup time or memory.
class IndonesiaRegionLocalDataSource {
  IndonesiaRegionLocalDataSource(this._bundle);

  final AssetBundle _bundle;

  IndonesiaRegionCatalog? _catalog;
  final Map<String, Map<String, List<PrayerVillage>>> _villagesByProvince = {};

  Future<IndonesiaRegionCatalog> catalog() async {
    final cached = _catalog;
    if (cached != null) return cached;

    final raw = jsonDecode(
      await _bundle.loadString(AppAssets.indonesiaRegions),
    ) as Map<String, dynamic>;

    final provinceTimeZones = <String, String>{};
    final provinces = <PrayerProvince>[];
    final provincesById = <String, PrayerProvince>{};
    for (final row in raw['provinces'] as List<dynamic>) {
      final values = row as List<dynamic>;
      final province = PrayerProvince(
        id: values[0] as String,
        name: values[1] as String,
        latitude: (values[2] as num).toDouble(),
        longitude: (values[3] as num).toDouble(),
        timeZoneId: values[4] as String,
      );
      provinceTimeZones[province.id] = province.timeZoneId;
      provincesById[province.id] = province;
      provinces.add(province);
    }

    final regenciesByProvince = <String, List<PrayerRegency>>{};
    final regenciesById = <String, PrayerRegency>{};
    for (final row in raw['regencies'] as List<dynamic>) {
      final values = row as List<dynamic>;
      final provinceId = values[1] as String;
      final regency = PrayerRegency(
        id: values[0] as String,
        provinceId: provinceId,
        name: values[2] as String,
        latitude: (values[3] as num).toDouble(),
        longitude: (values[4] as num).toDouble(),
        timeZoneId: provinceTimeZones[provinceId] ?? 'Asia/Jakarta',
      );
      regenciesById[regency.id] = regency;
      regenciesByProvince.putIfAbsent(provinceId, () => []).add(regency);
    }

    final districtsByRegency = <String, List<PrayerDistrict>>{};
    final districtsById = <String, PrayerDistrict>{};
    for (final row in raw['districts'] as List<dynamic>) {
      final values = row as List<dynamic>;
      final regencyId = values[1] as String;
      final regency = regenciesById[regencyId];
      if (regency == null) continue;
      final district = PrayerDistrict(
        id: values[0] as String,
        regencyId: regencyId,
        provinceId: regency.provinceId,
        name: values[2] as String,
        latitude: (values[3] as num).toDouble(),
        longitude: (values[4] as num).toDouble(),
        timeZoneId: regency.timeZoneId,
      );
      districtsById[district.id] = district;
      districtsByRegency.putIfAbsent(regencyId, () => []).add(district);
    }

    return _catalog = IndonesiaRegionCatalog(
      provinces: provinces,
      provincesById: provincesById,
      regenciesByProvince: regenciesByProvince,
      regenciesById: regenciesById,
      districtsByRegency: districtsByRegency,
      districtsById: districtsById,
    );
  }

  /// Villages of a district, loaded from that district's province asset.
  Future<List<PrayerVillage>> villages({
    required String provinceId,
    required String districtId,
  }) async {
    final byDistrict = await _provinceVillages(provinceId);
    return byDistrict[districtId] ?? const [];
  }

  Future<Map<String, List<PrayerVillage>>> _provinceVillages(
    String provinceId,
  ) async {
    final cached = _villagesByProvince[provinceId];
    if (cached != null) return cached;

    final path = '${AppAssets.indonesiaVillageDirectory}/$provinceId.json';
    final raw =
        jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;
    final byDistrict = <String, List<PrayerVillage>>{};
    raw.forEach((districtId, rows) {
      byDistrict[districtId] = [
        for (final row in rows as List<dynamic>)
          PrayerVillage(
            id: (row as List<dynamic>)[0] as String,
            districtId: districtId,
            name: row[1] as String,
            latitude: (row[2] as num).toDouble(),
            longitude: (row[3] as num).toDouble(),
          ),
      ];
    });
    return _villagesByProvince[provinceId] = byDistrict;
  }
}
