import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

typedef DownloadProgress = void Function(int received, int total);

/// Stores downloaded murottal files under the app support directory.
///
/// Layout: `<support>/quran_audio/<reciter>/<surah>/<ayah>.mp3`.
class AudioFileStore {
  AudioFileStore({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  Directory? _root;

  Future<Directory> _ensureRoot() async {
    final cached = _root;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final root = Directory('${support.path}/quran_audio');
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return _root = root;
  }

  /// Indexes every completed `.mp3` file. Keys use the form
  /// `reciterId:surahNumber:ayahNumber`.
  Future<Map<String, String>> scan() async {
    final result = <String, String>{};
    final Directory root;
    try {
      root = await _ensureRoot();
    } catch (_) {
      return result;
    }
    if (!await root.exists()) return result;

    await for (final entity in root.list(recursive: true)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.mp3')) {
        continue;
      }
      final relative = entity.path
          .substring(root.path.length + 1)
          .replaceAll('\\', '/');
      final parts = relative.split('/');
      if (parts.length != 3) continue;
      final surah = int.tryParse(parts[1]);
      final ayah = int.tryParse(parts[2].replaceFirst('.mp3', ''));
      if (surah == null || ayah == null) continue;
      result['${parts[0]}:$surah:$ayah'] = entity.path;
    }
    return result;
  }

  Future<String> download({
    required String url,
    required String relativePath,
    DownloadProgress? onProgress,
  }) async {
    final root = await _ensureRoot();
    final file = File('${root.path}/$relativePath');
    await file.parent.create(recursive: true);

    final partial = File('${file.path}.part');
    if (await partial.exists()) await partial.delete();

    try {
      await _dio.download(
        url,
        partial.path,
        onReceiveProgress: onProgress,
        options: Options(receiveTimeout: const Duration(minutes: 2)),
      );
      if (await file.exists()) await file.delete();
      await partial.rename(file.path);
      return file.path;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  Future<void> deleteDirectory(String relativePath) async {
    try {
      final root = await _ensureRoot();
      final directory = Directory('${root.path}/$relativePath');
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {
      // A missing/unreadable folder already means there is nothing to delete.
    }
  }
}
