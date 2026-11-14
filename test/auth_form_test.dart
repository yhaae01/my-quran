import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/domain/entities/app_user.dart';
import 'package:my_quran/presentation/pages/challenge_page.dart';
import 'package:my_quran/presentation/providers/auth_providers.dart';
import 'package:my_quran/presentation/providers/core_providers.dart';

Widget _app() {
  return ProviderScope(
    overrides: [
      firebaseReadyProvider.overrideWithValue(true),
      authStateProvider.overrideWith((ref) => Stream<AppUser?>.value(null)),
    ],
    child: const MaterialApp(home: ChallengePage()),
  );
}

Future<void> _pumpSignIn(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
}

Future<void> _openRegister(WidgetTester tester) async {
  await tester.tap(find.text('Belum punya akun? Daftar'));
  await tester.pumpAndSettle();
}

bool _isObscured(WidgetTester tester, String key) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(EditableText),
    ),
  );
  return editable.obscureText;
}

void main() {
  testWidgets('shows the email form without Google sign-in', (tester) async {
    await _pumpSignIn(tester);

    expect(find.text('Masuk dengan email'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsNothing);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('register requires name, email and passwords', (tester) async {
    await _pumpSignIn(tester);
    await _openRegister(tester);

    expect(find.byKey(const Key('auth_confirm_password')), findsOneWidget);
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Nama tampilan wajib diisi.'), findsOneWidget);
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
    expect(find.text('Ulangi password.'), findsOneWidget);
  });

  testWidgets('validates email format, password length and confirmation', (
    tester,
  ) async {
    await _pumpSignIn(tester);
    await _openRegister(tester);

    await tester.enterText(find.byKey(const Key('auth_name')), 'Aisyah');
    await tester.enterText(find.byKey(const Key('auth_email')), 'bukan-email');
    await tester.enterText(find.byKey(const Key('auth_password')), '12345');
    await tester.enterText(
      find.byKey(const Key('auth_confirm_password')),
      '54321',
    );
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Format email tidak valid.'), findsOneWidget);
    expect(find.text('Kata sandi minimal 6 karakter.'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi tidak sama.'), findsOneWidget);
  });

  testWidgets('eye icons toggle password visibility', (tester) async {
    await _pumpSignIn(tester);
    await _openRegister(tester);

    expect(_isObscured(tester, 'auth_password'), isTrue);
    expect(_isObscured(tester, 'auth_confirm_password'), isTrue);

    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.tap(find.byTooltip('Tampilkan ulangi password'));
    await tester.pumpAndSettle();

    expect(_isObscured(tester, 'auth_password'), isFalse);
    expect(_isObscured(tester, 'auth_confirm_password'), isFalse);

    await tester.tap(find.byTooltip('Sembunyikan kata sandi'));
    await tester.tap(find.byTooltip('Sembunyikan ulangi password'));
    await tester.pumpAndSettle();

    expect(_isObscured(tester, 'auth_password'), isTrue);
    expect(_isObscured(tester, 'auth_confirm_password'), isTrue);
  });
}
