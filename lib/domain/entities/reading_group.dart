/// A private reading group joined through a 6-character invite code.
class ReadingGroup {
  const ReadingGroup({
    required this.id,
    required this.code,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.memberCount,
  });

  final String id;

  /// Six-character invite code shared with friends.
  final String code;
  final String name;
  final String ownerId;
  final DateTime? createdAt;
  final int memberCount;

  bool isOwner(String uid) => uid == ownerId;

  ReadingGroup copyWith({String? name, int? memberCount}) {
    return ReadingGroup(
      id: id,
      code: code,
      name: name ?? this.name,
      ownerId: ownerId,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
