import 'dart:math';

import '../../domain/entities/hadith.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../datasources/hadith_local_data_source.dart';

class HadithRepositoryImpl implements HadithRepository {
  HadithRepositoryImpl(this._dataSource);

  final HadithLocalDataSource _dataSource;

  @override
  Future<List<Hadith>> getHadiths() async {
    return await _dataSource.loadHadiths();
  }

  @override
  Future<Hadith> getRandomHadith([Random? random]) async {
    final list = await _dataSource.loadHadiths();
    return getRandomHadithFromList(list, random);
  }
}
