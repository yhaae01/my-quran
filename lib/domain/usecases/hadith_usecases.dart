import 'dart:math';

import '../../data/datasources/hadith_notification_data_source.dart';
import '../entities/hadith.dart';
import '../repositories/hadith_repository.dart';

class GetHadiths {
  const GetHadiths(this._repository);

  final HadithRepository _repository;

  Future<List<Hadith>> call() => _repository.getHadiths();
}

class GetRandomHadith {
  const GetRandomHadith(this._repository);

  final HadithRepository _repository;

  Future<Hadith> call([Random? random]) => _repository.getRandomHadith(random);
}

class ScheduleDailyHadithNotification {
  const ScheduleDailyHadithNotification({
    required this.repository,
    required this.notificationDataSource,
  });

  final HadithRepository repository;
  final HadithNotificationDataSource notificationDataSource;

  Future<void> call({
    String? timeZoneId,
    DateTime? fromDate,
    Random? random,
  }) async {
    final hadiths = await repository.getHadiths();
    await notificationDataSource.scheduleDailyHadiths(
      hadiths: hadiths,
      timeZoneId: timeZoneId,
      fromDate: fromDate,
      random: random,
    );
  }
}
