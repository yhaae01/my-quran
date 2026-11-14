import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/reading_group.dart';

/// Firestore representation of `groups/{groupId}`.
class ReadingGroupModel {
  const ReadingGroupModel({
    required this.id,
    required this.code,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.memberCount,
  });

  final String id;
  final String code;
  final String name;
  final String ownerId;
  final DateTime? createdAt;
  final int memberCount;

  factory ReadingGroupModel.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return ReadingGroupModel(
      id: id,
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? 'Grup bacaan',
      ownerId: data['ownerId'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory ReadingGroupModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return ReadingGroupModel.fromMap(snapshot.id, snapshot.data() ?? const {});
  }

  ReadingGroup toEntity() {
    return ReadingGroup(
      id: id,
      code: code,
      name: name,
      ownerId: ownerId,
      createdAt: createdAt,
      memberCount: memberCount,
    );
  }
}
