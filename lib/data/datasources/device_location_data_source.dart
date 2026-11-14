import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/error/failure.dart';
import '../../domain/entities/detected_location.dart';

/// Reads the device GPS position and its IANA timezone.
class DeviceLocationDataSource {
  static const Duration _timeout = Duration(seconds: 15);
  static const String _label = 'Lokasi saat ini';

  String get label => _label;

  Future<DetectedLocation> currentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const Failure(
        'Layanan lokasi perangkat belum aktif. Aktifkan GPS atau pilih kota '
        'secara manual.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const Failure(
        'Izin lokasi ditolak. Pilih kota secara manual untuk menghitung waktu '
        'shalat.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: _timeout,
        ),
      );
      final timezone = await FlutterTimezone.getLocalTimezone();
      return DetectedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timeZoneId: timezone.identifier,
        label: _label,
      );
    } catch (error) {
      debugPrint('Gagal membaca lokasi: $error');
      throw const Failure(
        'Lokasi tidak bisa dibaca. Pastikan GPS aktif lalu coba lagi, atau '
        'pilih kota secara manual.',
      );
    }
  }
}
