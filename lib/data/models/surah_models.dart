import '../../core/utils/text_utils.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';

class SurahModel {
  const SurahModel({
    required this.number,
    required this.name,
    required this.latinName,
    required this.meaning,
    required this.verseCount,
    required this.revelation,
    required this.description,
  });

  final int number;
  final String name;
  final String latinName;
  final String meaning;
  final int verseCount;
  final String revelation;
  final String description;

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number:
          (json['number'] as num?)?.toInt() ??
          (json['nomor'] as num?)?.toInt() ??
          0,
      name:
          (json['name'] as String?)?.trim() ??
          (json['nama'] as String?)?.trim() ??
          '',
      latinName:
          (json['latinName'] as String?)?.trim() ??
          (json['namaLatin'] as String?)?.trim() ??
          '',
      meaning:
          (json['meaning'] as String?)?.trim() ??
          (json['arti'] as String?)?.trim() ??
          '',
      verseCount:
          (json['verseCount'] as num?)?.toInt() ??
          (json['jumlahAyat'] as num?)?.toInt() ??
          0,
      revelation:
          (json['revelation'] as String?)?.trim() ??
          (json['tempatTurun'] as String?)?.trim() ??
          '',
      description: stripHtml(
        (json['description'] as String?) ??
            (json['deskripsi'] as String?) ??
            '',
      ),
    );
  }

  factory SurahModel.fromEquran(Map<String, dynamic> json) {
    return SurahModel(
      number: (json['nomor'] as num?)?.toInt() ?? 0,
      name: (json['nama'] as String? ?? '').trim(),
      latinName: (json['namaLatin'] as String? ?? '').trim(),
      meaning: (json['arti'] as String? ?? '').trim(),
      verseCount: (json['jumlahAyat'] as num?)?.toInt() ?? 0,
      revelation: (json['tempatTurun'] as String? ?? '').trim(),
      description: stripHtml(json['deskripsi'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'latinName': latinName,
      'meaning': meaning,
      'verseCount': verseCount,
      'revelation': revelation,
      'description': description,
    };
  }

  Surah toEntity() {
    return Surah(
      number: number,
      name: name,
      latinName: latinName,
      meaning: meaning,
      verseCount: verseCount,
      revelation: revelation,
      description: description,
    );
  }
}

class AyahModel {
  const AyahModel({
    required this.number,
    required this.arabic,
    required this.translation,
    this.uthmani,
    this.audioUrl,
    this.audioUrls = const {},
  });

  final int number;
  final String arabic;
  final String? uthmani;
  final String translation;
  final String? audioUrl;
  final Map<String, String> audioUrls;

  factory AyahModel.fromEquran(Map<String, dynamic> json) {
    final audioUrls = _extractAudioMap(json['audio']);
    return AyahModel(
      number: (json['nomorAyat'] as num?)?.toInt() ?? 0,
      arabic: (json['teksArab'] as String? ?? '').trim(),
      translation: (json['teksIndonesia'] as String? ?? '').trim(),
      audioUrl: _firstAudio(audioUrls),
      audioUrls: audioUrls,
    );
  }

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['audioUrls'];
    final audioUrls = rawUrls is Map
        ? {
            for (final entry in rawUrls.entries)
              if (entry.value is String && (entry.value as String).isNotEmpty)
                entry.key.toString(): entry.value as String,
          }
        : const <String, String>{};
    return AyahModel(
      number: (json['number'] as num?)?.toInt() ?? 0,
      arabic: (json['arabic'] as String? ?? '').trim(),
      uthmani: (json['uthmani'] as String?)?.trim(),
      translation: (json['translation'] as String? ?? '').trim(),
      audioUrl: json['audioUrl'] as String?,
      audioUrls: audioUrls,
    );
  }

  AyahModel withUthmani(String? text) {
    return AyahModel(
      number: number,
      arabic: arabic,
      uthmani: text,
      translation: translation,
      audioUrl: audioUrl,
      audioUrls: audioUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'arabic': arabic,
      'uthmani': uthmani,
      'translation': translation,
      'audioUrl': audioUrl,
      'audioUrls': audioUrls,
    };
  }

  Ayah toEntity(int surahNumber) {
    return Ayah(
      surahNumber: surahNumber,
      number: number,
      arabic: arabic,
      uthmani: uthmani,
      translation: translation,
      audioUrl: audioUrl,
      audioUrls: audioUrls,
    );
  }

  static Map<String, String> _extractAudioMap(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, String>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) {
        result[entry.key.toString()] = value;
      }
    }
    return result;
  }

  static String? _firstAudio(Map<String, String> urls) {
    if (urls.isEmpty) return null;
    final keys = urls.keys.toList()..sort();
    return urls[keys.first];
  }
}

class SurahDetailModel {
  const SurahDetailModel({required this.surah, required this.ayahs});

  final SurahModel surah;
  final List<AyahModel> ayahs;

  factory SurahDetailModel.fromEquran(Map<String, dynamic> json) {
    final rawAyahs = json['ayat'];
    if (rawAyahs is! List) {
      throw const FormatException('Daftar ayat tidak ditemukan.');
    }
    return SurahDetailModel(
      surah: SurahModel.fromEquran(json),
      ayahs: [
        for (final raw in rawAyahs)
          if (raw is Map) AyahModel.fromEquran(Map<String, dynamic>.from(raw)),
      ]..sort((a, b) => a.number.compareTo(b.number)),
    );
  }

  factory SurahDetailModel.fromJson(Map<String, dynamic> json) {
    final rawSurah = json['surah'];
    final rawAyahs = json['ayahs'];
    if (rawSurah is! Map || rawAyahs is! List) {
      throw const FormatException('Data surah tersimpan tidak valid.');
    }
    return SurahDetailModel(
      surah: SurahModel.fromJson(Map<String, dynamic>.from(rawSurah)),
      ayahs: [
        for (final raw in rawAyahs)
          if (raw is Map) AyahModel.fromJson(Map<String, dynamic>.from(raw)),
      ]..sort((a, b) => a.number.compareTo(b.number)),
    );
  }

  SurahDetailModel withUthmani(Map<int, String> byVerse) {
    if (byVerse.isEmpty) return this;
    return SurahDetailModel(
      surah: surah,
      ayahs: [for (final ayah in ayahs) ayah.withUthmani(byVerse[ayah.number])],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah': surah.toJson(),
      'ayahs': [for (final ayah in ayahs) ayah.toJson()],
    };
  }

  SurahDetail toEntity() {
    return SurahDetail(
      surah: surah.toEntity(),
      ayahs: [for (final ayah in ayahs) ayah.toEntity(surah.number)],
    );
  }
}
