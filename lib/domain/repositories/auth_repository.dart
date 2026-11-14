import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Currently signed-in user, or null when the visitor has not signed in yet.
  AppUser? get currentUser;

  Stream<AppUser?> authStateChanges();

  Future<AppUser> signInAnonymously();

  /// Returns null when the visitor dismisses the Google account chooser.
  Future<AppUser?> signInWithGoogle();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> updateDisplayName(String displayName);

  Future<void> signOut();
}
