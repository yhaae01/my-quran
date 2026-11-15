import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/hadith.dart';
import '../models/hadith_model.dart';

class HadithLocalDataSource {
  HadithLocalDataSource({this.bundle, this.box});

  final AssetBundle? bundle;
  final Box<dynamic>? box;

  static const String _cacheKey = 'cached_hadiths';

  /// Loads hadiths from Hive cache if available, falling back to the bundled
  /// offline JSON asset from renomureza/hadis-api-id dataset.
  Future<List<Hadith>> loadHadiths() async {
    // 1. Try loading from Hive cache first
    try {
      final cached = box?.get(_cacheKey);
      if (cached != null) {
        final List<dynamic> rawList = cached is String
            ? jsonDecode(cached) as List<dynamic>
            : (cached as List<dynamic>);
        if (rawList.isNotEmpty) {
          return rawList.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return HadithModel.fromJson(map).toEntity();
          }).toList();
        }
      }
    } catch (_) {
      // Fall through to asset on cache read failure
    }

    // 2. Load from bundled asset
    final effectiveBundle = bundle ?? rootBundle;
    final jsonString = await effectiveBundle.loadString(AppAssets.hadiths);
    final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;

    final hadiths = decoded.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return HadithModel.fromJson(map).toEntity();
    }).toList();

    // 3. Cache into Hive for offline resilience
    await cacheHadiths(hadiths);

    return hadiths;
  }

  /// Caches a list of hadiths into Hive.
  Future<void> cacheHadiths(List<Hadith> hadiths) async {
    try {
      if (box != null) {
        final listMaps = hadiths
            .map((h) => HadithModel.fromEntity(h).toJson())
            .toList();
        await box!.put(_cacheKey, listMaps);
      }
    } catch (_) {
      // Ignored if box is unavailable
    }
  }

  /// Fetches from a remote URL (e.g. renomureza/hadis-api-id repository),
  /// merges with local cache, and persists.
  Future<List<Hadith>> parseAndCacheJsonString(
    String jsonString, {
    String defaultBook = 'Hadis',
    String? slug,
  }) async {
    final decoded = jsonDecode(jsonString);
    List<Hadith> newHadiths = [];

    if (decoded is List) {
      newHadiths = decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (slug != null) map['slug'] = slug;
        return HadithModel.fromJson(map, defaultBook: defaultBook).toEntity();
      }).toList();
    } else if (decoded is Map && decoded['hadiths'] is List) {
      final bookName = decoded['name'] as String? ?? defaultBook;
      final bookSlug = decoded['slug'] as String? ?? slug;
      final list = decoded['hadiths'] as List;
      newHadiths = list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        map['book'] = bookName;
        if (bookSlug != null) map['slug'] = bookSlug;
        return HadithModel.fromJson(map, defaultBook: bookName).toEntity();
      }).toList();
    }

    if (newHadiths.isNotEmpty) {
      final current = await loadHadiths();
      final existingKeys = current.map((h) => '${h.book}_${h.number}').toSet();
      final merged = [...current];
      for (final h in newHadiths) {
        if (!existingKeys.contains('${h.book}_${h.number}')) {
          merged.add(h);
        }
      }
      await cacheHadiths(merged);
      return merged;
    }

    return await loadHadiths();
  }
}
