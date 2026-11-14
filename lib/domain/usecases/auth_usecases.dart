import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.authStateChanges();
}

class SignInAnonymously {
  const SignInAnonymously(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call() => _repository.signInAnonymously();
}

class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  Future<AppUser?> call() => _repository.signInWithGoogle();
}

class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

class RegisterWithEmail {
  const RegisterWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _repository.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}

class UpdateDisplayName {
  const UpdateDisplayName(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call(String displayName) {
    return _repository.updateDisplayName(displayName);
  }
}

class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
