import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/member_progress.dart';
import '../../domain/entities/reading_progress.dart';

/// Firestore representation of `groups/{groupId}/members/{uid}`.
class MemberProgressModel {
  const MemberProgressModel({
    required this.uid,
    required this.displayName,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.versesRead,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final int versesRead;
  final DateTime? updatedAt;

  factory MemberProgressModel.fromMap(String uid, Map<String, dynamic> data) {
    final updated = data['updatedAt'];
    return MemberProgressModel(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Pembaca',
      surahNumber: (data['surahNumber'] as num?)?.toInt() ?? 1,
      surahName: data['surahName'] as String? ?? 'Al-Fatihah',
      ayahNumber: (data['ayahNumber'] as num?)?.toInt() ?? 1,
      versesRead: (data['versesRead'] as num?)?.toInt() ?? 0,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }

  factory MemberProgressModel.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return MemberProgressModel.fromMap(snapshot.id, snapshot.data());
  }

  MemberProgress toEntity() {
    return MemberProgress(
      uid: uid,
      displayName: displayName,
      progress: ReadingProgress(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        surahName: surahName,
        updatedAt: updatedAt ?? DateTime.now(),
      ),
    );
  }
}
