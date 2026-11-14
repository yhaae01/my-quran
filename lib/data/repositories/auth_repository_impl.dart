import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/error/failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/google_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._google);

  final FirebaseAuthDataSource _auth;
  final GoogleAuthDataSource _google;

  @override
  AppUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_toUser);
  }

  @override
  Future<AppUser> signInAnonymously() {
    return _guard(() async => _toUser(await _auth.signInAnonymously())!);
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    if (kIsWeb) {
      return _guard(() async {
        try {
          return _toUser(await _auth.signInWithGooglePopup());
        } on FirebaseAuthException catch (error) {
          // Closing the popup is a cancellation, not a failure.
          if (_isGoogleCancellation(error)) return null;
          rethrow;
        }
      });
    }

    final idToken = await _guard(_google.signIn);
    // The visitor dismissed the account chooser; keep the current session.
    if (idToken == null) return null;

    try {
      return await _guard(
        () async => _toUser(await _auth.signInWithGoogle(idToken)),
      );
    } on Failure {
      // Firebase rejected the Google credential (for example because the email
      // is already linked to another provider). Clear the cached Google
      // session so the next attempt opens the account chooser again instead of
      // silently reusing a credential that cannot be exchanged.
      await _signOutGoogleQuietly();
      rethrow;
    }
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final user = await _auth.signInWithEmail(email.trim(), password);
      return _toUser(user)!;
    });
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _guard(() async {
      final user = await _auth.registerWithEmail(
        email.trim(),
        password,
        displayName.trim(),
      );
      return _toUser(user)!;
    });
  }

  @override
  Future<AppUser> updateDisplayName(String displayName) {
    return _guard(() async {
      final trimmed = displayName.trim();
      if (trimmed.isEmpty) {
        throw const Failure('Nama tidak boleh kosong.');
      }
      return _toUser(await _auth.updateDisplayName(trimmed))!;
    });
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _signOutGoogleQuietly();
  }

  Future<void> _signOutGoogleQuietly() async {
    try {
      await _google.signOut();
    } catch (_) {
      // The Firebase session is already cleared, so a Google SDK hiccup here
      // must not block signing out.
    }
  }

  static bool _isGoogleCancellation(FirebaseAuthException error) {
    return switch (error.code) {
      'popup-closed-by-user' ||
      'cancelled-popup-request' ||
      'web-context-cancelled' => true,
      _ => false,
    };
  }

  AppUser? _toUser(User? user) {
    if (user == null) return null;
    final storedName = user.displayName?.trim();
    final suffix = user.uid.length >= 4
        ? user.uid.substring(0, 4).toUpperCase()
        : user.uid.toUpperCase();
    return AppUser(
      uid: user.uid,
      displayName: storedName != null && storedName.isNotEmpty
          ? storedName
          : 'Pembaca $suffix',
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    // Wraps every auth call so SDK/network errors surface as a localized
    // [Failure] and cancellation stays a regular result.
    try {
      return await action();
    } on Failure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw Failure(_messageFor(error), cause: error);
    } on GoogleSignInException catch (error) {
      throw Failure(_googleMessageFor(error), cause: error);
    } on UnsupportedError catch (error) {
      throw Failure(
        'Masuk dengan Google belum tersedia di platform ini.',
        cause: error,
      );
    } catch (error) {
      throw Failure(
        'Tidak dapat menghubungi server. Periksa koneksi internet Anda.',
        kind: FailureKind.network,
        cause: error,
      );
    }
  }

  String _messageFor(FirebaseAuthException error) {
    final message = switch (error.code) {
      'invalid-email' => 'Format email tidak valid.',
      'user-disabled' => 'Akun ini telah dinonaktifkan.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email atau kata sandi salah.',
      'email-already-in-use' => 'Email ini sudah terdaftar. Silakan masuk.',
      'weak-password' => 'Kata sandi minimal 6 karakter.',
      'network-request-failed' =>
        'Tidak ada koneksi internet. Coba lagi nanti.',
      'operation-not-allowed' =>
        'Metode masuk ini belum diaktifkan di Firebase Console.',
      'admin-restricted-operation' => 'Masuk sebagai tamu belum diaktifkan. Aktifkan Anonymous di Firebase Console → Authentication → Sign-in method.',
      'account-exists-with-different-credential' =>
        'Email ini sudah terdaftar dengan metode masuk lain.',
      'too-many-requests' =>
        'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.',
      _ => error.message ?? 'Gagal masuk. Coba lagi.',
    };
    return message;
  }

  String _googleMessageFor(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled => 'Masuk dengan Google dibatalkan.',
      GoogleSignInExceptionCode.interrupted =>
        'Masuk dengan Google terganggu. Coba lagi.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Jendela masuk Google tidak dapat ditampilkan. Coba lagi.',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Konfigurasi Google Sign-In belum lengkap. Pastikan OAuth client sudah '
            'dibuat di Firebase Console dan file konfigurasi sudah diunduh ulang.',
      _ => error.description ?? 'Gagal masuk dengan Google. Coba lagi.',
    };
  }
}
