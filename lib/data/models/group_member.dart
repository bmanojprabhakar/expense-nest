class GroupMember {
  final int? id;
  final int groupId;
  final int userId;
  final DateTime joinedAt;
  final bool isActive;

  GroupMember({
    this.id,
    required this.groupId,
    required this.userId,
    required this.joinedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      userId: map['user_id'] as int,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  GroupMember copyWith({
    int? id,
    int? groupId,
    int? userId,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'GroupMember(id: $id, groupId: $groupId, userId: $userId, joinedAt: $joinedAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember &&
        other.id == id &&
        other.groupId == groupId &&
        other.userId == userId &&
        other.joinedAt == joinedAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        groupId.hashCode ^
        userId.hashCode ^
        joinedAt.hashCode ^
        isActive.hashCode;
  }
}