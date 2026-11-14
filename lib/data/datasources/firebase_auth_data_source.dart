import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper that keeps Firebase Auth types inside the data layer.
class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Future<User> signInWithGoogle(String idToken) async {
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    return result.user!;
  }

  /// Web-only flow: Google Sign-In on web must run through a Firebase popup.
  Future<User> signInWithGooglePopup() async {
    final result = await _auth.signInWithPopup(GoogleAuthProvider());
    return result.user!;
  }

  Future<User> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  Future<User> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName);
    await user.reload();
    return _auth.currentUser ?? user;
  }

  Future<User> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Belum ada akun yang masuk.',
      );
    }
    await user.updateDisplayName(displayName);
    await user.reload();
    return _auth.currentUser ?? user;
  }

  Future<void> signOut() => _auth.signOut();
}
