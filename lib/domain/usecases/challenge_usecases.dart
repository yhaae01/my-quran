import '../entities/daily_tilawah.dart';
import '../entities/member_progress.dart';
import '../entities/reading_group.dart';
import '../entities/reading_progress.dart';
import '../repositories/challenge_repository.dart';

class CreateReadingGroup {
  const CreateReadingGroup(this._repository);

  final ChallengeRepository _repository;

  Future<ReadingGroup> call(String name) => _repository.createGroup(name);
}

class JoinReadingGroup {
  const JoinReadingGroup(this._repository);

  final ChallengeRepository _repository;

  Future<ReadingGroup> call(String code) => _repository.joinGroup(code);
}

class WatchMyGroups {
  const WatchMyGroups(this._repository);

  final ChallengeRepository _repository;

  Stream<List<ReadingGroup>> call() => _repository.watchMyGroups();
}

class WatchReadingGroup {
  const WatchReadingGroup(this._repository);

  final ChallengeRepository _repository;

  Stream<ReadingGroup?> call(String groupId) => _repository.watchGroup(groupId);
}

class WatchGroupMembers {
  const WatchGroupMembers(this._repository);

  final ChallengeRepository _repository;

  Stream<List<MemberProgress>> call(String groupId) =>
      _repository.watchMembers(groupId);
}

class SyncReadingProgress {
  const SyncReadingProgress(this._repository);

  final ChallengeRepository _repository;

  Future<void> call(ReadingProgress progress, {DailyTilawah? daily}) =>
      _repository.syncProgress(progress, daily: daily);
}

class LeaveReadingGroup {
  const LeaveReadingGroup(this._repository);

  final ChallengeRepository _repository;

  Future<void> call(String groupId) => _repository.leaveGroup(groupId);
}

class DeleteReadingGroup {
  const DeleteReadingGroup(this._repository);

  final ChallengeRepository _repository;

  Future<void> call(String groupId) => _repository.deleteGroup(groupId);
}
