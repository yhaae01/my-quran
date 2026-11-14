import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../error/failure.dart';

/// Thin JSON-over-HTTP wrapper. Every transport or decoding problem is turned
/// into a [Failure] so callers never see raw client exceptions.
class ApiClient {
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 20)})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<Map<String, dynamic>> getJson(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
          .timeout(timeout);

      if (response.statusCode == 404) {
        throw const Failure(
          'Data yang diminta tidak ditemukan.',
          kind: FailureKind.notFound,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Failure(
          'Server mengembalikan kode ${response.statusCode}.',
          kind: FailureKind.server,
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const Failure(
          'Format respons server tidak dikenali.',
          kind: FailureKind.parse,
        );
      }
      return decoded;
    } on Failure {
      rethrow;
    } on TimeoutException catch (error) {
      throw Failure(
        'Koneksi habis waktu. Periksa jaringan lalu coba lagi.',
        kind: FailureKind.timeout,
        cause: error,
      );
    } on FormatException catch (error) {
      throw Failure(
        'Respons server tidak dapat dibaca.',
        kind: FailureKind.parse,
        cause: error,
      );
    } catch (error) {
      throw Failure(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        kind: FailureKind.network,
        cause: error,
      );
    }
  }

  void dispose() => _client.close();
}
