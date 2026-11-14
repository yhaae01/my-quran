import '../entities/detected_location.dart';

abstract interface class LocationRepository {
  Future<DetectedLocation> detectCurrent();
}
