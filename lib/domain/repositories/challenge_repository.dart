import '../entities/member_progress.dart';
import '../entities/reading_group.dart';
import '../entities/reading_progress.dart';

abstract interface class ChallengeRepository {
  /// Creates a group with a fresh invite code and adds the caller as owner.
  Future<ReadingGroup> createGroup(String name);

  /// Joins the group behind [code] and returns it.
  Future<ReadingGroup> joinGroup(String code);

  /// Groups the signed-in user belongs to, newest first.
  Stream<List<ReadingGroup>> watchMyGroups();

  Stream<ReadingGroup?> watchGroup(String groupId);

  /// Members of [groupId] ordered by verses read, highest first.
  Stream<List<MemberProgress>> watchMembers(String groupId);

  /// Pushes local progress to every group of the signed-in user.
  Future<void> syncProgress(ReadingProgress progress);

  Future<void> leaveGroup(String groupId);

  Future<void> deleteGroup(String groupId);
}
