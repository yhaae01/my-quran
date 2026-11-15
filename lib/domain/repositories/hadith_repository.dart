import 'dart:math';

import '../entities/hadith.dart';

/// Helper function that picks 1 random Hadith (including its title/number,
/// Arabic text, and Indonesian translation) from a dataset list.
Hadith getRandomHadithFromList(List<Hadith> hadiths, [Random? random]) {
  if (hadiths.isEmpty) {
    return const Hadith(
      book: 'Shahih Bukhari',
      number: 1,
      arabic: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
      translation: 'Semua perbuatan tergantung niatnya, dan balasan bagi tiap-tiap orang tergantung apa yang diniatkan.',
    );
  }
  final rng = random ?? Random();
  final index = rng.nextInt(hadiths.length);
  return hadiths[index];
}

abstract interface class HadithRepository {
  /// Returns all available hadiths from cache or asset dataset.
  Future<List<Hadith>> getHadiths();

  /// Picks 1 random Hadith from the dataset.
  Future<Hadith> getRandomHadith([Random? random]);
}
