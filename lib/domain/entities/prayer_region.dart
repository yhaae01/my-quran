/// Administrative regions used by the prayer location picker.
///
/// Indonesia is organised as province (provinsi) → regency/city
/// (kabupaten/kota) → district (kecamatan) → village (desa/kelurahan). Every
/// level carries coordinates so prayer times can be calculated from the exact
/// place instead of a handful of major cities.
class PrayerProvince {
  const PrayerProvince({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String timeZoneId;

  String get timeZoneLabel => prayerTimeZoneLabel(timeZoneId);
}

class PrayerRegency {
  const PrayerRegency({
    required this.id,
    required this.provinceId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
  });

  final String id;
  final String provinceId;
  final String name;
  final double latitude;
  final double longitude;
  final String timeZoneId;

  String get timeZoneLabel => prayerTimeZoneLabel(timeZoneId);
}

class PrayerDistrict {
  const PrayerDistrict({
    required this.id,
    required this.regencyId,
    required this.provinceId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
  });

  final String id;
  final String regencyId;
  final String provinceId;
  final String name;
  final double latitude;
  final double longitude;
  final String timeZoneId;

  String get timeZoneLabel => prayerTimeZoneLabel(timeZoneId);
}

class PrayerVillage {
  const PrayerVillage({
    required this.id,
    required this.districtId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String districtId;
  final String name;
  final double latitude;
  final double longitude;
}

/// A district together with its parents, used for search results and GPS
/// reverse matching. When [village] is set the coordinates of the village are
/// preferred over the district centroid.
class PrayerRegionMatch {
  const PrayerRegionMatch({
    required this.province,
    required this.regency,
    required this.district,
    this.village,
  });

  final PrayerProvince province;
  final PrayerRegency regency;
  final PrayerDistrict district;
  final PrayerVillage? village;

  String get id => district.id;

  String? get villageId => village?.id;

  double get latitude => village?.latitude ?? district.latitude;

  double get longitude => village?.longitude ?? district.longitude;

  String get timeZoneId => district.timeZoneId;

  String get timeZoneLabel => prayerTimeZoneLabel(timeZoneId);

  /// Short label shown on the prayer screen, e.g. "Kec. Cibadak, Kabupaten
  /// Sukabumi" or "Desa/Kel. Sekarwangi, Kec. Cibadak".
  String get label {
    final value = village;
    if (value == null) {
      return 'Kec. ${district.name}, ${regency.name}';
    }
    return 'Desa/Kel. ${value.name}, Kec. ${district.name}';
  }

  /// Full context used in search results.
  String get contextLabel =>
      'Kec. ${district.name}, ${regency.name}, ${province.name}';
}

String prayerTimeZoneLabel(String timeZoneId) => switch (timeZoneId) {
  'Asia/Jakarta' => 'WIB',
  'Asia/Makassar' => 'WITA',
  'Asia/Jayapura' => 'WIT',
  _ => timeZoneId,
};
