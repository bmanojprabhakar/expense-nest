class Transaction {
  final int? id;
  final double amount;
  final DateTime date;
  final String? note;
  final String? description;
  final int accountId;
  final int categoryId;
  final bool isShared;
  final int? groupId; // Null for personal transactions, set for shared ones
  final DateTime createdAt;
  final DateTime? updatedAt;

  Transaction({
    this.id,
    required this.amount,
    required this.date,
    this.note,
    this.description,
    required this.accountId,
    required this.categoryId,
    this.isShared = false,
    this.groupId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'description': description,
      'account_id': accountId,
      'category_id': categoryId,
      'is_shared': isShared ? 1 : 0,
      'group_id': groupId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      description: map['description'] as String?,
      accountId: map['account_id'] as int,
      categoryId: map['category_id'] as int,
      isShared: (map['is_shared'] as int) == 1,
      groupId: map['group_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Transaction copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? note,
    String? description,
    int? accountId,
    int? categoryId,
    bool? isShared,
    int? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      description: description ?? this.description,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      isShared: isShared ?? this.isShared,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, date: $date, note: $note, description: $description, accountId: $accountId, categoryId: $categoryId, isShared: $isShared, groupId: $groupId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.amount == amount &&
        other.date == date &&
        other.note == note &&
        other.description == description &&
        other.accountId == accountId &&
        other.categoryId == categoryId &&
        other.isShared == isShared &&
        other.groupId == groupId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        date.hashCode ^
        note.hashCode ^
        description.hashCode ^
        accountId.hashCode ^
        categoryId.hashCode ^
        isShared.hashCode ^
        groupId.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}