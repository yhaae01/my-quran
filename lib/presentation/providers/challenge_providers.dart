import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/member_progress.dart';
import '../../domain/entities/reading_group.dart';
import 'auth_providers.dart';
import 'core_providers.dart';

/// Live list of groups the signed-in reader belongs to.
final StreamProvider<List<ReadingGroup>> myGroupsProvider =
    StreamProvider<List<ReadingGroup>>((ref) {
      ref.watch(authStateProvider);
      if (!ref.watch(firebaseReadyProvider)) {
        return Stream.value(const []);
      }
      return ref.watch(watchMyGroupsProvider)();
    });

final readingGroupProvider = StreamProvider.family<ReadingGroup?, String>((
  ref,
  groupId,
) {
  if (!ref.watch(firebaseReadyProvider)) {
    return Stream.value(null);
  }
  return ref.watch(watchReadingGroupProvider)(groupId);
});

final groupMembersProvider =
    StreamProvider.family<List<MemberProgress>, String>((ref, groupId) {
      if (!ref.watch(firebaseReadyProvider)) {
        return Stream.value(const []);
      }
      return ref.watch(watchGroupMembersProvider)(groupId);
    });

class ChallengeController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ReadingGroup> createGroup(String name) async {
    return _run(() => ref.read(createReadingGroupProvider)(name));
  }

  Future<ReadingGroup> joinGroup(String code) async {
    return _run(() => ref.read(joinReadingGroupProvider)(code));
  }

  Future<void> leaveGroup(String groupId) async {
    await _run(() => ref.read(leaveReadingGroupProvider)(groupId));
  }

  Future<void> deleteGroup(String groupId) async {
    await _run(() => ref.read(deleteReadingGroupProvider)(groupId));
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    state = const AsyncValue.loading();
    try {
      final result = await action();
      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final AsyncNotifierProvider<ChallengeController, void>
challengeControllerProvider = AsyncNotifierProvider<ChallengeController, void>(
  ChallengeController.new,
);
