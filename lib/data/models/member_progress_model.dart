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
    this.dailyPages = 0,
    this.dailyTargetPages = 20,
    this.dailyCompleted = false,
    this.dailyDate,
  });

  final String uid;
  final String displayName;
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final int versesRead;
  final DateTime? updatedAt;
  final double dailyPages;
  final int dailyTargetPages;
  final bool dailyCompleted;
  final String? dailyDate;

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
      dailyPages: (data['dailyPages'] as num?)?.toDouble() ?? 0,
      dailyTargetPages: (data['dailyTargetPages'] as num?)?.toInt() ?? 20,
      dailyCompleted: data['dailyCompleted'] as bool? ?? false,
      dailyDate: data['dailyDate'] as String?,
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
      dailyPages: dailyPages,
      dailyTargetPages: dailyTargetPages,
      dailyCompleted: dailyCompleted,
      dailyDate: dailyDate,
    );
  }
}
