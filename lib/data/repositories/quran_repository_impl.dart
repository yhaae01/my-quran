import '../../core/error/failure.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';
import '../datasources/quran_remote_data_source.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({required this.remote, required this.local});

  final QuranRemoteDataSource remote;
  final QuranLocalDataSource local;

  List<Surah>? _surahMemory;
  final Map<int, SurahDetail> _detailMemory = {};

  @override
  Future<List<Surah>> getSurahs({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final memory = _surahMemory;
      if (memory != null) return memory;

      final cached = local.readSurahList();
      if (cached != null) {
        final surahs = cached.map((model) => model.toEntity()).toList();
        _surahMemory = surahs;
        return surahs;
      }
    }

    try {
      final models = await remote.fetchSurahs();
      await local.writeSurahList(models);
      final surahs = models.map((model) => model.toEntity()).toList();
      _surahMemory = surahs;
      return surahs;
    } catch (error) {
      final stale = local.readSurahList(allowStale: true);
      if (stale != null) {
        final surahs = stale.map((model) => model.toEntity()).toList();
        _surahMemory = surahs;
        return surahs;
      }
      throw _asFailure(error);
    }
  }

  @override
  Future<SurahDetail> getSurahDetail(
    int surahNumber, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final memory = _detailMemory[surahNumber];
      if (memory != null) return memory;

      final cached = local.readSurahDetail(surahNumber);
      if (cached != null) {
        final detail = cached.toEntity();
        _detailMemory[surahNumber] = detail;
        return detail;
      }
    }

    try {
      final uthmaniFuture = _safeUthmani(surahNumber);
      final model = await remote.fetchSurahDetail(surahNumber);
      final uthmani = await uthmaniFuture;
      final enriched = model.withUthmani(uthmani);

      await local.writeSurahDetail(surahNumber, enriched);
      final detail = enriched.toEntity();
      _detailMemory[surahNumber] = detail;
      return detail;
    } catch (error) {
      final stale = local.readSurahDetail(surahNumber, allowStale: true);
      if (stale != null) {
        final detail = stale.toEntity();
        _detailMemory[surahNumber] = detail;
        return detail;
      }
      throw _asFailure(error);
    }
  }

  Future<Map<int, String>> _safeUthmani(int surahNumber) async {
    try {
      return await remote.fetchUthmaniVerses(surahNumber);
    } catch (_) {
      // The Madinah script is an enhancement; Indonesian text remains usable.
      return const {};
    }
  }

  Failure _asFailure(Object error) {
    if (error is Failure) return error;
    return Failure(
      'Terjadi kesalahan saat memuat data Al-Qur\'an.',
      cause: error,
    );
  }
}
