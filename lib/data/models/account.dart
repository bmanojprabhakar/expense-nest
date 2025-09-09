class Account {
  final int? id;
  final String name;
  final int? parentId; // Hierarchical parent reference
  final String? accountType; // Optional type/category
  final double balance;
  final DateTime createdAt;
  final bool isActive;
  
  // Credit card specific fields
  final int? statementDay;  // Day of month when statement is generated (1-31)
  final int? gracePeriodDays; // Number of days from statement day to pay without interest

  Account({
    this.id,
    required this.name,
    this.parentId,
    this.accountType,
    required this.balance,
    required this.createdAt,
    this.isActive = true,
    this.statementDay,
    this.gracePeriodDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'account_type': accountType,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'statement_day': statementDay,
      'grace_period_days': gracePeriodDays,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
      accountType: map['account_type'] as String?,
      balance: (map['balance'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int) == 1,
      statementDay: map['statement_day'] as int?,
      gracePeriodDays: map['grace_period_days'] as int?,
    );
  }

  Account copyWith({
    int? id,
    String? name,
    int? parentId,
    String? accountType,
    double? balance,
    DateTime? createdAt,
    bool? isActive,
    int? statementDay,
    int? gracePeriodDays,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      accountType: accountType ?? this.accountType,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      statementDay: statementDay ?? this.statementDay,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
    );
  }

  @override
  String toString() {
    return 'Account(id: $id, name: $name, parentId: $parentId, accountType: $accountType, balance: $balance, createdAt: $createdAt, isActive: $isActive, statementDay: $statementDay, gracePeriodDays: $gracePeriodDays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.name == name &&
        other.parentId == parentId &&
        other.accountType == accountType &&
        other.balance == balance &&
        other.createdAt == createdAt &&
        other.isActive == isActive &&
        other.statementDay == statementDay &&
        other.gracePeriodDays == gracePeriodDays;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        parentId.hashCode ^
        accountType.hashCode ^
        balance.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode ^
        statementDay.hashCode ^
        gracePeriodDays.hashCode;
  }

  bool get isRoot => parentId == null;
  String get legacyType => accountType ?? 'unknown';
  
  bool isCreditCardWithParent(String? parentName) {
    return parentName?.toLowerCase() == 'credit cards';
  }
  
  bool get isCreditCard {
    return statementDay != null || gracePeriodDays != null;
  }
  
  DateTime? getPaymentDueDate(DateTime statementDate) {
    if (!isCreditCard || gracePeriodDays == null) return null;
    return statementDate.add(Duration(days: gracePeriodDays!));
  }
}