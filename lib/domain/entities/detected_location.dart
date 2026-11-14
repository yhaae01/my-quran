/// A GPS fix together with the device's IANA timezone.
class DetectedLocation {
  const DetectedLocation({
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
    this.label = 'Lokasi saat ini',
  });

  final double latitude;
  final double longitude;
  final String timeZoneId;
  final String label;
}
