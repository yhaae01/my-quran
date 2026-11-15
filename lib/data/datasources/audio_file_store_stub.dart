typedef DownloadProgress = void Function(int received, int total);

/// Web has no persistent application directory, so downloads stay disabled and
/// playback keeps streaming from the CDN.
class AudioFileStore {
  AudioFileStore({Object? dio});

  Future<Map<String, String>> scan() async => const {};

  Future<String> download({
    required String url,
    required String relativePath,
    DownloadProgress? onProgress,
  }) {
    throw UnsupportedError(
      'Unduhan audio hanya tersedia di aplikasi Android atau iOS.',
    );
  }

  Future<void> deleteDirectory(String relativePath) async {}
}
