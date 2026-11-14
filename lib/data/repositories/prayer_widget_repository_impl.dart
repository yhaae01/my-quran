import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_preferences.dart';
import '../../domain/repositories/prayer_widget_repository.dart';
import '../datasources/prayer_widget_data_source.dart';

class PrayerWidgetRepositoryImpl implements PrayerWidgetRepository {
  PrayerWidgetRepositoryImpl(this._dataSource);

  final PrayerWidgetDataSource _dataSource;

  @override
  Future<void> sync(PrayerSchedule schedule, PrayerPreferences preferences) =>
      _dataSource.update(schedule, preferences);

  @override
  Future<bool> canPin() => _dataSource.canPin();

  @override
  Future<void> pin() => _dataSource.pin();
}
