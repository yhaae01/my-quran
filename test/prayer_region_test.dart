import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/data/datasources/indonesia_region_local_data_source.dart';
import 'package:my_quran/data/repositories/region_repository_impl.dart';
import 'package:my_quran/domain/entities/prayer_region.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tz_data.initializeTimeZones);

  late RegionRepositoryImpl regions;

  setUpAll(() {
    regions = RegionRepositoryImpl(IndonesiaRegionLocalDataSource(rootBundle));
  });

  test(
    'bundles every province, regency and kecamatan with coordinates',
    () async {
      final catalog = await IndonesiaRegionLocalDataSource(rootBundle)
          .catalog();

      expect(catalog.provinces, hasLength(34));
      expect(catalog.regenciesById, hasLength(514));
      expect(catalog.districtsById, hasLength(7215));

      for (final province in catalog.provinces) {
        expect(province.latitude, inInclusiveRange(-11, 6));
        expect(province.longitude, inInclusiveRange(95, 141));
        expect(
          () => tz.getLocation(province.timeZoneId),
          returnsNormally,
          reason: province.name,
        );
      }
      for (final district in catalog.districtsById.values) {
        expect(district.latitude, inInclusiveRange(-11, 6));
        expect(district.longitude, inInclusiveRange(95, 141));
        expect(
          () => tz.getLocation(district.timeZoneId),
          returnsNormally,
          reason: district.name,
        );
      }
    },
  );

  test('browses the hierarchy from province to kecamatan', () async {
    final provinces = await regions.provinces();
    final westJava = provinces.firstWhere((item) => item.id == '32');
    expect(westJava.name, 'Jawa Barat');
    expect(westJava.timeZoneLabel, 'WIB');

    final regencies = await regions.regenciesOf('32');
    expect(regencies.map((item) => item.id), contains('3204'));
    final bandung = regencies.firstWhere((item) => item.id == '3204');
    expect(bandung.name, 'Kabupaten Bandung');

    final districts = await regions.districtsOf('3204');
    expect(districts.map((item) => item.id), contains('3204010'));
    final ciwidey = districts.firstWhere((item) => item.id == '3204010');
    expect(ciwidey.name, 'Ciwidey');
    expect(ciwidey.provinceId, '32');
    expect(ciwidey.timeZoneId, 'Asia/Jakarta');
  });

  test('loads desa/kelurahan with their own coordinates', () async {
    final villages = await regions.villagesOf('3204010');

    expect(villages, isNotEmpty);
    expect(villages.map((item) => item.name), contains('Ciwidey'));
    for (final village in villages) {
      expect(village.districtId, '3204010');
      expect(village.latitude, inInclusiveRange(-11, 6));
      expect(village.longitude, inInclusiveRange(95, 141));
    }
  });

  test(
    'searches kecamatan across districts, regencies and provinces',
    () async {
      final results = await regions.search('cibadak');
      expect(results, isNotEmpty);
      expect(results.map((item) => item.district.name), contains('Cibadak'));
      expect(
        results.any(
          (item) =>
              item.regency.name == 'Kabupaten Sukabumi' &&
              item.province.name == 'Jawa Barat',
        ),
        isTrue,
      );

      // Administrative prefixes are ignored so "Kecamatan Ciwidey" still finds it.
      final prefixed = await regions.search('Kecamatan Ciwidey');
      expect(prefixed.first.district.id, '3204010');

      // Regency name searches work too.
      final byRegency = await regions.search('sukabumi');
      expect(byRegency, isNotEmpty);
      expect(
        byRegency.any(
          (item) =>
              item.regency.name.contains('Sukabumi') ||
              item.district.name.contains('Sukabumi'),
        ),
        isTrue,
      );

      expect(await regions.search('   '), isEmpty);
    },
  );

  test('resolves the nearest kecamatan from a GPS fix', () async {
    final jakarta = await regions.nearest(
      latitude: -6.2088,
      longitude: 106.8456,
    );
    expect(jakarta, isNotNull);
    expect(jakarta!.district.provinceId, '31');
    expect(jakarta.timeZoneId, 'Asia/Jakarta');

    final ciwidey = await regions.nearest(latitude: -7.097, longitude: 107.438);
    expect(ciwidey?.district.id, '3204010');

    // Far outside Indonesia, so no misleading district is returned.
    expect(
      await regions.nearest(latitude: 51.5074, longitude: -0.1278),
      isNull,
    );
  });

  test('builds readable labels for kecamatan and desa', () {
    const province = PrayerProvince(
      id: '32',
      name: 'Jawa Barat',
      latitude: -6.9,
      longitude: 107.6,
      timeZoneId: 'Asia/Jakarta',
    );
    const regency = PrayerRegency(
      id: '3204',
      provinceId: '32',
      name: 'Kabupaten Bandung',
      latitude: -7.02,
      longitude: 107.5,
      timeZoneId: 'Asia/Jakarta',
    );
    const district = PrayerDistrict(
      id: '3204010',
      regencyId: '3204',
      provinceId: '32',
      name: 'Ciwidey',
      latitude: -7.097,
      longitude: 107.438,
      timeZoneId: 'Asia/Jakarta',
    );
    const village = PrayerVillage(
      id: '3204010002',
      districtId: '3204010',
      name: 'Ciwidey',
      latitude: -7.089,
      longitude: 107.444,
    );

    const districtOnly = PrayerRegionMatch(
      province: province,
      regency: regency,
      district: district,
    );
    expect(districtOnly.label, 'Kec. Ciwidey, Kabupaten Bandung');
    expect(
      districtOnly.contextLabel,
      'Kec. Ciwidey, Kabupaten Bandung, Jawa Barat',
    );

    const withVillage = PrayerRegionMatch(
      province: province,
      regency: regency,
      district: district,
      village: village,
    );
    expect(withVillage.label, 'Desa/Kel. Ciwidey, Kec. Ciwidey');
    expect(withVillage.latitude, village.latitude);
    expect(withVillage.longitude, village.longitude);
  });
}
