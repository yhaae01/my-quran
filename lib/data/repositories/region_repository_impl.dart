import 'dart:math' as math;

import '../../domain/entities/prayer_region.dart';
import '../../domain/repositories/region_repository.dart';
import '../datasources/indonesia_region_local_data_source.dart';

class RegionRepositoryImpl implements RegionRepository {
  RegionRepositoryImpl(this._dataSource);

  final IndonesiaRegionLocalDataSource _dataSource;

  static const Set<String> _searchStopWords = {
    'kecamatan',
    'kec',
    'kabupaten',
    'kab',
    'kota',
    'provinsi',
    'propinsi',
    'desa',
    'kelurahan',
    'kel',
    'di',
    'dki',
  };

  @override
  Future<List<PrayerProvince>> provinces() async =>
      (await _dataSource.catalog()).provinces;

  @override
  Future<List<PrayerRegency>> regenciesOf(String provinceId) async {
    final catalog = await _dataSource.catalog();
    return catalog.regenciesByProvince[provinceId] ?? const [];
  }

  @override
  Future<List<PrayerDistrict>> districtsOf(String regencyId) async {
    final catalog = await _dataSource.catalog();
    return catalog.districtsByRegency[regencyId] ?? const [];
  }

  @override
  Future<List<PrayerVillage>> villagesOf(String districtId) async {
    final catalog = await _dataSource.catalog();
    final district = catalog.districtsById[districtId];
    if (district == null) return const [];
    return _dataSource.villages(
      provinceId: district.provinceId,
      districtId: districtId,
    );
  }

  @override
  Future<List<PrayerRegionMatch>> search(String query, {int limit = 80}) async {
    var tokens = query
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList();
    final meaningful = tokens.where(
      (token) => !_searchStopWords.contains(token),
    );
    if (meaningful.isNotEmpty) tokens = meaningful.toList();
    if (tokens.isEmpty) return const [];

    final catalog = await _dataSource.catalog();
    final scored = <({int score, PrayerRegionMatch match})>[];
    for (final district in catalog.districtsById.values) {
      final regency = catalog.regenciesById[district.regencyId];
      final province = regency == null
          ? null
          : catalog.provincesById[regency.provinceId];
      if (regency == null || province == null) continue;

      final districtName = district.name.toLowerCase();
      final haystack =
          '$districtName ${regency.name.toLowerCase()} '
          '${province.name.toLowerCase()}';
      if (!tokens.every(haystack.contains)) continue;

      final compactQuery = tokens.join(' ');
      final score = districtName == compactQuery
          ? 0
          : districtName.startsWith(compactQuery)
          ? 1
          : districtName.contains(compactQuery)
          ? 2
          : 3;
      scored.add((
        score: score,
        match: PrayerRegionMatch(
          province: province,
          regency: regency,
          district: district,
        ),
      ));
    }

    scored.sort((a, b) {
      final byScore = a.score.compareTo(b.score);
      if (byScore != 0) return byScore;
      return a.match.district.name.compareTo(b.match.district.name);
    });
    return [for (final entry in scored.take(limit)) entry.match];
  }

  @override
  Future<PrayerRegionMatch?> districtById(String districtId) async {
    final catalog = await _dataSource.catalog();
    final district = catalog.districtsById[districtId];
    if (district == null) return null;
    final regency = catalog.regenciesById[district.regencyId];
    if (regency == null) return null;
    final province = catalog.provincesById[regency.provinceId];
    if (province == null) return null;
    return PrayerRegionMatch(
      province: province,
      regency: regency,
      district: district,
    );
  }

  @override
  Future<PrayerRegionMatch?> nearest({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 120,
  }) async {
    final catalog = await _dataSource.catalog();
    PrayerDistrict? closest;
    var closestDistance = double.infinity;
    for (final district in catalog.districtsById.values) {
      final distance = _distanceKm(
        latitude,
        longitude,
        district.latitude,
        district.longitude,
      );
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = district;
      }
    }
    if (closest == null || closestDistance > maxDistanceKm) return null;
    return districtById(closest.id);
  }

  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(lat2 - lat1);
    final dLon = _radians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
