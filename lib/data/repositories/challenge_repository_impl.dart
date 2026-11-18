import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/daily_tilawah.dart';
import '../../domain/entities/member_progress.dart';
import '../../domain/entities/reading_group.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../datasources/challenge_remote_data_source.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  ChallengeRepositoryImpl(this._remote, this._auth, this._progress);

  final ChallengeRemoteDataSource _remote;
  final AuthRepository _auth;
  final ReadingProgressRepository _progress;

  @override
  Future<ReadingGroup> createGroup(String name) async {
    final user = _requireUser();
    return _guard(() async {
      final model = await _remote.createGroup(
        uid: user.uid,
        displayName: user.displayName,
        name: name,
        progress: _progress.load(),
      );
      return model.toEntity();
    });
  }

  @override
  Future<ReadingGroup> joinGroup(String code) async {
    final user = _requireUser();
    return _guard(() async {
      final model = await _remote.joinGroup(
        uid: user.uid,
        displayName: user.displayName,
        code: code,
        progress: _progress.load(),
      );
      return model.toEntity();
    });
  }

  @override
  Stream<List<ReadingGroup>> watchMyGroups() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const []);
    return _guardStream(
      _remote
          .watchMyGroups(user.uid)
          .map((groups) => groups.map((model) => model.toEntity()).toList()),
    );
  }

  @override
  Stream<ReadingGroup?> watchGroup(String groupId) {
    return _guardStream(
      _remote.watchGroup(groupId).map((model) => model?.toEntity()),
    );
  }

  @override
  Stream<List<MemberProgress>> watchMembers(String groupId) {
    return _guardStream(
      _remote
          .watchMembers(groupId)
          .map((members) => members.map((model) => model.toEntity()).toList()),
    );
  }

  @override
  Future<void> syncProgress(
    ReadingProgress progress, {
    DailyTilawah? daily,
  }) async {
    final user = _requireUser();
    await _guard(
      () => _remote.syncProgress(
        uid: user.uid,
        displayName: user.displayName,
        progress: progress,
        daily: daily,
      ),
    );
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    final user = _requireUser();
    await _guard(() => _remote.leaveGroup(uid: user.uid, groupId: groupId));
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final user = _requireUser();
    await _guard(() => _remote.deleteGroup(uid: user.uid, groupId: groupId));
  }

  AppUser _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const Failure('Masuk terlebih dahulu untuk mengikuti tantangan.');
    }
    return user;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } on FirebaseException catch (error) {
      throw _failureFor(error);
    } catch (error) {
      throw Failure(
        'Tidak dapat menyinkronkan data. Periksa koneksi internet Anda.',
        kind: FailureKind.network,
        cause: error,
      );
    }
  }

  Stream<T> _guardStream<T>(Stream<T> stream) {
    return stream.transform(
      StreamTransformer<T, T>.fromHandlers(
        handleError: (error, stackTrace, sink) {
          sink.addError(
            error is FirebaseException ? _failureFor(error) : error,
            stackTrace,
          );
        },
      ),
    );
  }

  Failure _failureFor(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' => const Failure(
        'Akses ke grup ditolak. Periksa aturan Firestore Anda.',
        kind: FailureKind.server,
      ),
      'unavailable' => const Failure(
        'Server tidak dapat dijangkau. Periksa koneksi internet Anda.',
        kind: FailureKind.network,
      ),
      'not-found' => const Failure(
        'Grup tidak ditemukan.',
        kind: FailureKind.notFound,
      ),
      _ => Failure(
        'Gagal memproses tantangan bacaan. Coba lagi.',
        kind: FailureKind.server,
        cause: error,
      ),
    };
  }
}
