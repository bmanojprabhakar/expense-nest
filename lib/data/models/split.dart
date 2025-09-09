class Split {
  final int? id;
  final int transactionId;
  final int userId;
  final double shareAmount;
  final double sharePercentage; // For easier reporting
  final DateTime createdAt;

  Split({
    this.id,
    required this.transactionId,
    required this.userId,
    required this.shareAmount,
    required this.sharePercentage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'user_id': userId,
      'share_amount': shareAmount,
      'share_percentage': sharePercentage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Split.fromMap(Map<String, dynamic> map) {
    return Split(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int,
      userId: map['user_id'] as int,
      shareAmount: (map['share_amount'] as num).toDouble(),
      sharePercentage: (map['share_percentage'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Split copyWith({
    int? id,
    int? transactionId,
    int? userId,
    double? shareAmount,
    double? sharePercentage,
    DateTime? createdAt,
  }) {
    return Split(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      shareAmount: shareAmount ?? this.shareAmount,
      sharePercentage: sharePercentage ?? this.sharePercentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Split(id: $id, transactionId: $transactionId, userId: $userId, shareAmount: $shareAmount, sharePercentage: $sharePercentage, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Split &&
        other.id == id &&
        other.transactionId == transactionId &&
        other.userId == userId &&
        other.shareAmount == shareAmount &&
        other.sharePercentage == sharePercentage &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        transactionId.hashCode ^
        userId.hashCode ^
        shareAmount.hashCode ^
        sharePercentage.hashCode ^
        createdAt.hashCode;
  }

  // Utility methods for common split scenarios
  static List<Split> createEqualSplits({
    required int transactionId,
    required List<int> userIds,
    required double totalAmount,
  }) {
    final DateTime now = DateTime.now();
    final double shareAmount = totalAmount / userIds.length;
    final double sharePercentage = 100.0 / userIds.length;

    return userIds.map((userId) => Split(
      transactionId: transactionId,
      userId: userId,
      shareAmount: shareAmount,
      sharePercentage: sharePercentage,
      createdAt: now,
    )).toList();
  }

  static List<Split> createCustomSplits({
    required int transactionId,
    required Map<int, double> userShares, // userId -> amount
    required double totalAmount,
  }) {
    final DateTime now = DateTime.now();
    
    return userShares.entries.map((entry) {
      final userId = entry.key;
      final shareAmount = entry.value;
      final sharePercentage = (shareAmount / totalAmount) * 100;

      return Split(
        transactionId: transactionId,
        userId: userId,
        shareAmount: shareAmount,
        sharePercentage: sharePercentage,
        createdAt: now,
      );
    }).toList();
  }

  static List<Split> createPercentageSplits({
    required int transactionId,
    required Map<int, double> userPercentages, // userId -> percentage
    required double totalAmount,
  }) {
    final DateTime now = DateTime.now();
    
    return userPercentages.entries.map((entry) {
      final userId = entry.key;
      final sharePercentage = entry.value;
      final shareAmount = (totalAmount * sharePercentage) / 100;

      return Split(
        transactionId: transactionId,
        userId: userId,
        shareAmount: shareAmount,
        sharePercentage: sharePercentage,
        createdAt: now,
      );
    }).toList();
  }
}