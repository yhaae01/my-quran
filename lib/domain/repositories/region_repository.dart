import '../entities/prayer_region.dart';

/// Read-only access to the bundled Indonesian administrative regions.
abstract interface class RegionRepository {
  Future<List<PrayerProvince>> provinces();

  Future<List<PrayerRegency>> regenciesOf(String provinceId);

  Future<List<PrayerDistrict>> districtsOf(String regencyId);

  Future<List<PrayerVillage>> villagesOf(String districtId);

  /// Searches kecamatan by district, regency, or province name.
  Future<List<PrayerRegionMatch>> search(String query, {int limit = 80});

  Future<PrayerRegionMatch?> districtById(String districtId);

  /// Finds the closest kecamatan to a GPS fix so automatic mode can show the
  /// actual rural district instead of a distant major city.
  Future<PrayerRegionMatch?> nearest({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 120,
  });
}
