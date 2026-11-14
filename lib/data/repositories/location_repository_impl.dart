import '../../domain/entities/detected_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/device_location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._dataSource);

  final DeviceLocationDataSource _dataSource;

  @override
  Future<DetectedLocation> detectCurrent() => _dataSource.currentLocation();
}
