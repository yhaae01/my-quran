import 'dart:math';

/// Human-friendly alphabet without I, O, 0 and 1 so codes are easy to read
/// aloud or type from a screenshot.
const String inviteCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

abstract final class InviteCode {
  static const int length = 6;

  static final RegExp _pattern = RegExp(
    '^[${inviteCodeAlphabet.substring(0, 24)}2-9]{$length}\$',
  );

  /// Generates a random 6-character code. Pass [random] for deterministic tests.
  static String generate({Random? random}) {
    final source = random ?? Random.secure();
    return List.generate(
      length,
      (_) => inviteCodeAlphabet[source.nextInt(inviteCodeAlphabet.length)],
    ).join();
  }

  /// Uppercases a typed code and drops spaces or dashes.
  static String normalize(String input) {
    return input.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static bool isValid(String code) => _pattern.hasMatch(code);
}
