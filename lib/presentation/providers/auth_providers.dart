import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import 'core_providers.dart';

/// Emits null while signed out and keeps the UI in sync with Firebase Auth.
final StreamProvider<AppUser?> authStateProvider = StreamProvider<AppUser?>((
  ref,
) {
  if (!ref.watch(firebaseReadyProvider)) return Stream.value(null);
  return ref.watch(watchAuthStateProvider)();
});

final Provider<AppUser?> currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authStateProvider).value,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInAnonymously() {
    return _run(() => ref.read(signInAnonymouslyProvider)());
  }

  Future<void> signIn({required String email, required String password}) {
    return _run(
      () => ref.read(signInWithEmailProvider)(email: email, password: password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _run(
      () => ref.read(registerWithEmailProvider)(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> updateDisplayName(String displayName) {
    return _run(() => ref.read(updateDisplayNameProvider)(displayName));
  }

  Future<void> signOut() {
    return _run(() => ref.read(signOutProvider)());
  }

  Future<void> _run(Future<Object?> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final AsyncNotifierProvider<AuthController, void> authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
