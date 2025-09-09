class Category {
  final int? id;
  final String name;
  final String type; // 'income', 'expense'
  final String? icon;
  final String? color;
  final bool isActive;
  final bool isDefault; // System-provided categories

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isActive = true,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isActive: (map['is_active'] as int) == 1,
      isDefault: (map['is_default'] as int) == 1,
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isActive,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type, icon: $icon, color: $color, isActive: $isActive, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.icon == icon &&
        other.color == color &&
        other.isActive == isActive &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        type.hashCode ^
        icon.hashCode ^
        color.hashCode ^
        isActive.hashCode ^
        isDefault.hashCode;
  }

  // Predefined expense categories
  static List<Category> getDefaultExpenseCategories() {
    return [
      Category(name: 'Food & Dining', type: 'expense', icon: '🍽️', isDefault: true),
      Category(name: 'Groceries', type: 'expense', icon: '🛒', isDefault: true),
      Category(name: 'Transportation', type: 'expense', icon: '🚗', isDefault: true),
      Category(name: 'Shopping', type: 'expense', icon: '🛍️', isDefault: true),
      Category(name: 'Entertainment', type: 'expense', icon: '🎬', isDefault: true),
      Category(name: 'Bills & Utilities', type: 'expense', icon: '💡', isDefault: true),
      Category(name: 'Healthcare', type: 'expense', icon: '⚕️', isDefault: true),
      Category(name: 'Education', type: 'expense', icon: '📚', isDefault: true),
      Category(name: 'Travel', type: 'expense', icon: '✈️', isDefault: true),
      Category(name: 'Personal Care', type: 'expense', icon: '💄', isDefault: true),
      Category(name: 'Home & Garden', type: 'expense', icon: '🏠', isDefault: true),
      Category(name: 'Gifts & Donations', type: 'expense', icon: '🎁', isDefault: true),
      Category(name: 'Other', type: 'expense', icon: '📝', isDefault: true),
    ];
  }

  // Predefined income categories
  static List<Category> getDefaultIncomeCategories() {
    return [
      Category(name: 'Salary', type: 'income', icon: '💰', isDefault: true),
      Category(name: 'Business', type: 'income', icon: '💼', isDefault: true),
      Category(name: 'Investment', type: 'income', icon: '📈', isDefault: true),
      Category(name: 'Rental', type: 'income', icon: '🏠', isDefault: true),
      Category(name: 'Freelance', type: 'income', icon: '💻', isDefault: true),
      Category(name: 'Gift', type: 'income', icon: '🎁', isDefault: true),
      Category(name: 'Other', type: 'income', icon: '📝', isDefault: true),
    ];
  }
}