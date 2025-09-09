class ExpenseGroup {
  final int? id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  ExpenseGroup({
    this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory ExpenseGroup.fromMap(Map<String, dynamic> map) {
    return ExpenseGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  ExpenseGroup copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ExpenseGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'ExpenseGroup(id: $id, name: $name, description: $description, createdAt: $createdAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseGroup &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }

  // Default groups
  static List<ExpenseGroup> getDefaultGroups() {
    final now = DateTime.now();
    return [
      ExpenseGroup(name: 'Family', description: 'Family shared expenses', createdAt: now),
      ExpenseGroup(name: 'Spouse', description: 'Expenses shared with spouse', createdAt: now),
    ];
  }
}