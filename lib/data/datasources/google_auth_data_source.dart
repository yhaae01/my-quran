import 'package:google_sign_in/google_sign_in.dart';

/// Wraps the Google Sign-In SDK so the rest of the app only deals with ID
/// tokens.
///
/// Android reads the web OAuth client from `google-services.json`, while iOS
/// needs `GIDClientID` + the reversed client ID URL scheme in `Info.plist`.
class GoogleAuthDataSource {
  GoogleAuthDataSource({GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  Future<void>? _initialization;

  /// Returns an ID token for the selected Google account.
  ///
  /// Returns `null` when the account chooser is dismissed or no account can be
  /// signed in silently — cancellation is a normal outcome and must not be
  /// surfaced as an error.
  Future<String?> signIn() async {
    await _ensureInitialized();
    if (!_signIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google Sign-In interaktif tidak didukung di platform ini.',
      );
    }

    // First try to reuse a Google session that is already authorized on this
    // device, so returning users skip the account picker.
    final restoredToken = await _restoredIdToken();
    if (restoredToken != null) return restoredToken;

    final GoogleSignInAccount account;
    try {
      account = await _signIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description:
            'ID token Google kosong. Periksa konfigurasi OAuth di Firebase '
            'Console dan pastikan google-services.json/GoogleService-Info.plist '
            'sudah diunduh ulang.',
      );
    }
    return idToken;
  }

  Future<void> signOut() => _signIn.signOut();

  /// Silent sign-in with an existing Google session. Any failure here simply
  /// falls through to the interactive chooser.
  Future<String?> _restoredIdToken() async {
    try {
      final attempt = _signIn.attemptLightweightAuthentication();
      if (attempt == null) return null;
      final account = await attempt;
      return account?.authentication.idToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureInitialized() async {
    final existing = _initialization;
    if (existing != null) return existing;

    final future = _signIn.initialize();
    _initialization = future;
    try {
      await future;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }
}
