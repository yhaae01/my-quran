/// Signed-in Firebase account, anonymous or email based.
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.isAnonymous = false,
  });

  final String uid;
  final String displayName;
  final String? email;
  final bool isAnonymous;

  /// Short monogram for leaderboard avatars.
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _firstLetter(parts.first);
    return '${_firstLetter(parts.first)}${_firstLetter(parts[1])}';
  }

  static String _firstLetter(String value) =>
      value.substring(0, 1).toUpperCase();

  AppUser copyWith({String? displayName, String? email}) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isAnonymous: isAnonymous,
    );
  }
}
