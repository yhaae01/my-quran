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

  /// Shows the Google account chooser and returns the resulting ID token.
  Future<String> signIn() async {
    await _ensureInitialized();
    if (!_signIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google Sign-In interaktif tidak didukung di platform ini.',
      );
    }

    final account = await _signIn.authenticate();
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
