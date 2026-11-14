/// A city with bundled coordinates and IANA timezone, so prayer times can be
/// calculated without a network call or a location permission.
class PrayerCity {
  const PrayerCity({
    required this.id,
    required this.name,
    required this.province,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
  });

  final String id;
  final String name;
  final String province;
  final double latitude;
  final double longitude;
  final String timeZoneId;

  String get timeZoneLabel => switch (timeZoneId) {
    'Asia/Jakarta' => 'WIB',
    'Asia/Makassar' => 'WITA',
    'Asia/Jayapura' => 'WIT',
    _ => timeZoneId,
  };

  String get label => '$name ($timeZoneLabel)';
}

const PrayerCity defaultPrayerCity = PrayerCity(
  id: 'jakarta',
  name: 'Jakarta',
  province: 'DKI Jakarta',
  latitude: -6.2088,
  longitude: 106.8456,
  timeZoneId: 'Asia/Jakarta',
);

const List<PrayerCity> indonesianPrayerCities = [
  defaultPrayerCity,
  PrayerCity(
    id: 'bandung',
    name: 'Bandung',
    province: 'Jawa Barat',
    latitude: -6.9175,
    longitude: 107.6191,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'surabaya',
    name: 'Surabaya',
    province: 'Jawa Timur',
    latitude: -7.2575,
    longitude: 112.7521,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'semarang',
    name: 'Semarang',
    province: 'Jawa Tengah',
    latitude: -6.9667,
    longitude: 110.4167,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'yogyakarta',
    name: 'Yogyakarta',
    province: 'DI Yogyakarta',
    latitude: -7.7956,
    longitude: 110.3695,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'malang',
    name: 'Malang',
    province: 'Jawa Timur',
    latitude: -7.9666,
    longitude: 112.6326,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'medan',
    name: 'Medan',
    province: 'Sumatera Utara',
    latitude: 3.5952,
    longitude: 98.6722,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'palembang',
    name: 'Palembang',
    province: 'Sumatera Selatan',
    latitude: -2.9761,
    longitude: 104.7754,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'padang',
    name: 'Padang',
    province: 'Sumatera Barat',
    latitude: -0.9471,
    longitude: 100.4172,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'pekanbaru',
    name: 'Pekanbaru',
    province: 'Riau',
    latitude: 0.5071,
    longitude: 101.4478,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'batam',
    name: 'Batam',
    province: 'Kepulauan Riau',
    latitude: 1.1301,
    longitude: 104.0529,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'banda-aceh',
    name: 'Banda Aceh',
    province: 'Aceh',
    latitude: 5.5483,
    longitude: 95.3238,
    timeZoneId: 'Asia/Jakarta',
  ),
  PrayerCity(
    id: 'pontianak',
    name: 'Pontianak',
    province: 'Kalimantan Barat',
    latitude: -0.0263,
    longitude: 109.3425,
    timeZoneId: 'Asia/Pontianak',
  ),
  PrayerCity(
    id: 'banjarmasin',
    name: 'Banjarmasin',
    province: 'Kalimantan Selatan',
    latitude: -3.3186,
    longitude: 114.5944,
    timeZoneId: 'Asia/Makassar',
  ),
  PrayerCity(
    id: 'balikpapan',
    name: 'Balikpapan',
    province: 'Kalimantan Timur',
    latitude: -1.2379,
    longitude: 116.8529,
    timeZoneId: 'Asia/Makassar',
  ),
  PrayerCity(
    id: 'samarinda',
    name: 'Samarinda',
    province: 'Kalimantan Timur',
    latitude: -0.5017,
    longitude: 117.1536,
    timeZoneId: 'Asia/Makassar',
  ),
  PrayerCity(
    id: 'makassar',
    name: 'Makassar',
    province: 'Sulawesi Selatan',
    latitude: -5.1477,
    longitude: 119.4327,
    timeZoneId: 'Asia/Makassar',
  ),
  PrayerCity(
    id: 'manado',
    name: 'Manado',
    province: 'Sulawesi Utara',
    latitude: 1.4748,
    longitude: 124.8421,
    timeZoneId: 'Asia/Makassar',
  ),
  PrayerCity(
    id: 'denpasar',
    name: 'Denpasar',
    province: 'Bali',
    latitude: -8.6705,
    longitude: 115.2126,
    timeZoneId: 'Asia/Makassar',
  ),
  PrayerCity(
    id: 'mataram',
    name: 'Mataram',
    province: 'Nusa Tenggara Barat',
    latitude: -8.5833,
    longitude: 116.1167,
    timeZoneId: 'Asia/Makassar',
  ),
  PrayerCity(
    id: 'kupang',
    name: 'Kupang',
    province: 'Nusa Tenggara Timur',
    latitude: -10.1772,
    longitude: 123.607,
    timeZoneId: 'Asia/Makassar',
  ),
  PrayerCity(
    id: 'ambon',
    name: 'Ambon',
    province: 'Maluku',
    latitude: -3.6954,
    longitude: 128.1814,
    timeZoneId: 'Asia/Jayapura',
  ),
  PrayerCity(
    id: 'jayapura',
    name: 'Jayapura',
    province: 'Papua',
    latitude: -2.5916,
    longitude: 140.669,
    timeZoneId: 'Asia/Jayapura',
  ),
  PrayerCity(
    id: 'sorong',
    name: 'Sorong',
    province: 'Papua Barat Daya',
    latitude: -0.8762,
    longitude: 131.2558,
    timeZoneId: 'Asia/Jayapura',
  ),
];

PrayerCity prayerCityById(String id) {
  for (final city in indonesianPrayerCities) {
    if (city.id == id) return city;
  }
  return defaultPrayerCity;
}
