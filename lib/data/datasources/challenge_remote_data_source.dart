import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/failure.dart';
import '../../core/utils/invite_code.dart';
import '../../domain/entities/daily_tilawah.dart';
import '../../domain/entities/reading_progress.dart';
import '../models/member_progress_model.dart';
import '../models/reading_group_model.dart';

/// Firestore layout used by reading challenges:
///
/// * `groups/{groupId}` — name, invite code, owner and member list.
/// * `groups/{groupId}/members/{uid}` — last reading position per member.
/// * `groupCodes/{code}` — unique code reserved for a group.
class ChallengeRemoteDataSource {
  ChallengeRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String groupsCollection = 'groups';
  static const String membersCollection = 'members';
  static const String codesCollection = 'groupCodes';

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection(groupsCollection);

  Map<String, Object?> _memberFields({
    required String displayName,
    ReadingProgress? progress,
    DailyTilawah? daily,
  }) {
    final value =
        progress ??
        ReadingProgress(
          surahNumber: 1,
          ayahNumber: 1,
          surahName: 'Al-Fatihah',
          updatedAt: DateTime.now(),
        );
    return {
      'displayName': displayName,
      'surahNumber': value.surahNumber,
      'surahName': value.surahName,
      'ayahNumber': value.ayahNumber,
      'versesRead': value.versesRead,
      'updatedAt': FieldValue.serverTimestamp(),
      if (daily != null) ...{
        'dailyDate': daily.dateKey,
        'dailyPages': daily.pagesRead(value),
        'dailyTargetPages': daily.targetPages,
        'dailyCompleted': daily.isCompleteFor(value),
      },
    };
  }

  Future<ReadingGroupModel> createGroup({
    required String uid,
    required String displayName,
    required String name,
    ReadingProgress? progress,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const Failure('Nama grup tidak boleh kosong.');
    }

    final code = await _reserveCode();
    final groupRef = _groups.doc();
    final batch = _firestore.batch();

    batch.set(groupRef, {
      'name': trimmed,
      'code': code,
      'ownerId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'memberCount': 1,
      'memberUids': [uid],
    });
    batch.set(
      groupRef.collection(membersCollection).doc(uid),
      _memberFields(displayName: displayName, progress: progress),
    );
    batch.set(_firestore.collection(codesCollection).doc(code), {
      'groupId': groupRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return ReadingGroupModel(
      id: groupRef.id,
      code: code,
      name: trimmed,
      ownerId: uid,
      createdAt: DateTime.now(),
      memberCount: 1,
    );
  }

  Future<ReadingGroupModel> joinGroup({
    required String uid,
    required String displayName,
    required String code,
    ReadingProgress? progress,
  }) async {
    final normalized = InviteCode.normalize(code);
    if (!InviteCode.isValid(normalized)) {
      throw const Failure(
        'Kode undangan harus 6 karakter, tanpa huruf I, O, 0 atau 1.',
      );
    }

    final codeSnapshot = await _firestore
        .collection(codesCollection)
        .doc(normalized)
        .get();
    final groupId = codeSnapshot.data()?['groupId'];
    if (!codeSnapshot.exists || groupId is! String) {
      throw const Failure(
        'Kode undangan tidak ditemukan.',
        kind: FailureKind.notFound,
      );
    }

    final groupRef = _groups.doc(groupId);
    final groupSnapshot = await groupRef.get();
    if (!groupSnapshot.exists) {
      throw const Failure(
        'Grup untuk kode ini sudah tidak tersedia.',
        kind: FailureKind.notFound,
      );
    }

    final memberRef = groupRef.collection(membersCollection).doc(uid);
    final memberSnapshot = await memberRef.get();
    final batch = _firestore.batch();

    batch.set(
      memberRef,
      _memberFields(displayName: displayName, progress: progress),
      SetOptions(merge: true),
    );

    if (!memberSnapshot.exists) {
      batch.update(groupRef, {
        'memberCount': FieldValue.increment(1),
        'memberUids': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();

    final model = ReadingGroupModel.fromSnapshot(groupSnapshot);
    if (memberSnapshot.exists) return model;
    return ReadingGroupModel(
      id: model.id,
      code: model.code,
      name: model.name,
      ownerId: model.ownerId,
      createdAt: model.createdAt,
      memberCount: model.memberCount + 1,
    );
  }

  Stream<List<ReadingGroupModel>> watchMyGroups(String uid) {
    return _groups
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ReadingGroupModel.fromSnapshot).toList()
                ..sort(_newestFirst),
        );
  }

  Stream<ReadingGroupModel?> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return ReadingGroupModel.fromSnapshot(snapshot);
    });
  }

  Stream<List<MemberProgressModel>> watchMembers(String groupId) {
    return _groups
        .doc(groupId)
        .collection(membersCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(MemberProgressModel.fromSnapshot).toList()
                ..sort((a, b) => b.versesRead.compareTo(a.versesRead)),
        );
  }

  Future<void> syncProgress({
    required String uid,
    required String displayName,
    required ReadingProgress progress,
    DailyTilawah? daily,
  }) async {
    final snapshot = await _groups
        .where('memberUids', arrayContains: uid)
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final group in snapshot.docs) {
      batch.set(
        group.reference.collection(membersCollection).doc(uid),
        _memberFields(
          displayName: displayName,
          progress: progress,
          daily: daily,
        ),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> leaveGroup({
    required String uid,
    required String groupId,
  }) async {
    final groupRef = _groups.doc(groupId);
    final groupSnapshot = await groupRef.get();
    if (!groupSnapshot.exists) return;

    final memberRef = groupRef.collection(membersCollection).doc(uid);
    final memberSnapshot = await memberRef.get();
    if (!memberSnapshot.exists) return;

    final data = groupSnapshot.data() ?? const <String, dynamic>{};
    if (data['ownerId'] == uid) {
      final memberCount = (data['memberCount'] as num?)?.toInt() ?? 0;
      if (memberCount > 1) {
        throw const Failure(
          'Pemilik tidak dapat keluar selama grup masih memiliki anggota. '
          'Hapus grup bila tantangan sudah selesai.',
        );
      }
      await deleteGroup(uid: uid, groupId: groupId);
      return;
    }

    final batch = _firestore.batch();
    batch.delete(memberRef);
    batch.update(groupRef, {
      'memberCount': FieldValue.increment(-1),
      'memberUids': FieldValue.arrayRemove([uid]),
    });
    await batch.commit();
  }

  Future<void> deleteGroup({
    required String uid,
    required String groupId,
  }) async {
    final groupRef = _groups.doc(groupId);
    final groupSnapshot = await groupRef.get();
    if (!groupSnapshot.exists) return;

    final data = groupSnapshot.data() ?? const <String, dynamic>{};
    if (data['ownerId'] != uid) {
      throw const Failure('Hanya pembuat grup yang dapat menghapus grup ini.');
    }

    final members = await groupRef.collection(membersCollection).get();
    final batch = _firestore.batch();
    for (final member in members.docs) {
      batch.delete(member.reference);
    }
    batch.delete(groupRef);

    final code = data['code'];
    if (code is String && code.isNotEmpty) {
      batch.delete(_firestore.collection(codesCollection).doc(code));
    }
    await batch.commit();
  }

  /// Reserves a random code inside a transaction so two groups can never share
  /// the same invite code.
  Future<String> _reserveCode() async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final code = InviteCode.generate();
      final reference = _firestore.collection(codesCollection).doc(code);
      try {
        await _firestore.runTransaction<void>((transaction) async {
          final snapshot = await transaction.get(reference);
          if (snapshot.exists) throw const _CodeTakenException();
          transaction.set(reference, {
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
        return code;
      } on _CodeTakenException {
        continue;
      }
    }
    throw const Failure(
      'Tidak dapat membuat kode undangan unik. Coba lagi.',
      kind: FailureKind.server,
    );
  }

  static int _newestFirst(ReadingGroupModel a, ReadingGroupModel b) {
    final left = a.createdAt;
    final right = b.createdAt;
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }
}

class _CodeTakenException implements Exception {
  const _CodeTakenException();
}
