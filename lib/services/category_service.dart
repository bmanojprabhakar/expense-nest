import '../data/database/database_helper.dart';
import '../data/models/category.dart';

class CategoryService {
  final DatabaseHelper _databaseHelper;

  CategoryService(this._databaseHelper);

  // Create a new category
  Future<Category> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    if (!_isValidCategoryType(type)) {
      throw ArgumentError('Invalid category type: $type. Must be "income" or "expense"');
    }

    // Check if category with same name and type already exists
    final existingCategories = await getAllCategories(type: type);
    if (existingCategories.any((c) => c.name.toLowerCase() == name.trim().toLowerCase())) {
      throw ArgumentError('Category with name "$name" already exists for type "$type"');
    }

    final category = Category(
      name: name.trim(),
      type: type,
      icon: icon?.trim(),
      color: color?.trim(),
      isActive: true,
      isDefault: false, // Custom categories are not default
    );

    final id = await _databaseHelper.insertCategory(category);
    return category.copyWith(id: id);
  }

  // Get all active categories
  Future<List<Category>> getAllCategories({String? type, bool includeInactive = false}) async {
    return await _databaseHelper.getAllCategories(activeOnly: !includeInactive, type: type);
  }

  // Get income categories
  Future<List<Category>> getIncomeCategories({bool includeInactive = false}) async {
    return await getAllCategories(type: 'income', includeInactive: includeInactive);
  }

  // Get expense categories
  Future<List<Category>> getExpenseCategories({bool includeInactive = false}) async {
    return await getAllCategories(type: 'expense', includeInactive: includeInactive);
  }

  // Get category by ID
  Future<Category?> getCategoryById(int id) async {
    return await _databaseHelper.getCategory(id);
  }

  // Get default categories
  Future<List<Category>> getDefaultCategories({String? type}) async {
    final allCategories = await getAllCategories(type: type);
    return allCategories.where((category) => category.isDefault).toList();
  }

  // Get custom (user-created) categories
  Future<List<Category>> getCustomCategories({String? type}) async {
    final allCategories = await getAllCategories(type: type);
    return allCategories.where((category) => !category.isDefault).toList();
  }

  // Update category details
  Future<Category> updateCategory({
    required int id,
    String? name,
    String? type,
    String? icon,
    String? color,
  }) async {
    final existingCategory = await _databaseHelper.getCategory(id);
    if (existingCategory == null) {
      throw ArgumentError('Category with ID $id not found');
    }

    // Don't allow updating default categories' core properties
    if (existingCategory.isDefault && (name != null || type != null)) {
      throw ArgumentError('Cannot modify name or type of default categories');
    }

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    if (type != null && !_isValidCategoryType(type)) {
      throw ArgumentError('Invalid category type: $type. Must be "income" or "expense"');
    }

    // Check for name conflicts if name or type is being changed
    if (name != null || type != null) {
      final newName = name?.trim() ?? existingCategory.name;
      final newType = type ?? existingCategory.type;
      
      if (newName.toLowerCase() != existingCategory.name.toLowerCase() || newType != existingCategory.type) {
        final existingCategories = await getAllCategories(type: newType);
        if (existingCategories.any((c) => c.id != id && c.name.toLowerCase() == newName.toLowerCase())) {
          throw ArgumentError('Category with name "$newName" already exists for type "$newType"');
        }
      }
    }

    final updatedCategory = existingCategory.copyWith(
      name: name?.trim() ?? existingCategory.name,
      type: type ?? existingCategory.type,
      icon: icon?.trim() ?? existingCategory.icon,
      color: color?.trim() ?? existingCategory.color,
    );

    await _databaseHelper.updateCategory(updatedCategory);
    return updatedCategory;
  }

  // Deactivate category (soft delete)
  Future<void> deactivateCategory(int id) async {
    final existingCategory = await _databaseHelper.getCategory(id);
    if (existingCategory == null) {
      throw ArgumentError('Category with ID $id not found');
    }

    // Don't allow deactivating default categories
    if (existingCategory.isDefault) {
      throw ArgumentError('Cannot deactivate default categories');
    }

    // Check if category is being used by any transactions
    final canDelete = await _canDeleteCategory(id);
    if (!canDelete) {
      throw ArgumentError('Cannot deactivate category that is being used by transactions');
    }

    await _databaseHelper.deleteCategory(id);
  }

  // Reactivate category
  Future<Category> reactivateCategory(int id) async {
    final existingCategory = await _databaseHelper.getCategory(id);
    if (existingCategory == null) {
      throw ArgumentError('Category with ID $id not found');
    }

    final reactivatedCategory = existingCategory.copyWith(isActive: true);
    await _databaseHelper.updateCategory(reactivatedCategory);
    return reactivatedCategory;
  }

  // Get category usage statistics
  Future<CategoryUsageStats> getCategoryUsageStats(int categoryId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final category = await _databaseHelper.getCategory(categoryId);
    if (category == null) {
      throw ArgumentError('Category with ID $categoryId not found');
    }

    // This would require querying transactions - simplified for now
    // In a full implementation, you'd query the transactions table
    return CategoryUsageStats(
      categoryId: categoryId,
      transactionCount: 0, // To be implemented with transaction queries
      totalAmount: 0.0, // To be implemented with transaction queries
      averageAmount: 0.0, // To be implemented with transaction queries
      lastUsed: null, // To be implemented with transaction queries
    );
  }

  // Get most used categories
  Future<List<CategoryWithUsage>> getMostUsedCategories({
    String? type,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final categories = await getAllCategories(type: type);
    final categoriesWithUsage = <CategoryWithUsage>[];

    for (final category in categories) {
      final usage = await getCategoryUsageStats(category.id!, startDate: startDate, endDate: endDate);
      categoriesWithUsage.add(CategoryWithUsage(
        category: category,
        usage: usage,
      ));
    }

    // Sort by transaction count (descending) and take limit
    categoriesWithUsage.sort((a, b) => b.usage.transactionCount.compareTo(a.usage.transactionCount));
    return categoriesWithUsage.take(limit).toList();
  }

  // Initialize default categories (called during app setup)
  Future<void> initializeDefaultCategories() async {
    // Check if default categories are already initialized
    final existingCategories = await _databaseHelper.getAllCategories();
    if (existingCategories.isNotEmpty) {
      return; // Already initialized
    }

    // The DatabaseHelper already inserts default categories during database creation
    // This method can be used for re-initialization if needed
    final defaultExpenseCategories = Category.getDefaultExpenseCategories();
    final defaultIncomeCategories = Category.getDefaultIncomeCategories();

    for (final category in [...defaultExpenseCategories, ...defaultIncomeCategories]) {
      await _databaseHelper.insertCategory(category);
    }
  }

  // Search categories by name
  Future<List<Category>> searchCategories({
    required String query,
    String? type,
    bool includeInactive = false,
  }) async {
    if (query.trim().isEmpty) {
      return await getAllCategories(type: type, includeInactive: includeInactive);
    }

    final allCategories = await getAllCategories(type: type, includeInactive: includeInactive);
    final searchQuery = query.trim().toLowerCase();

    return allCategories.where((category) => 
      category.name.toLowerCase().contains(searchQuery)
    ).toList();
  }

  // Get category summary by type
  Future<CategorySummary> getCategorySummary() async {
    final allCategories = await getAllCategories();
    final incomeCategories = allCategories.where((c) => c.type == 'income').toList();
    final expenseCategories = allCategories.where((c) => c.type == 'expense').toList();

    return CategorySummary(
      totalCategories: allCategories.length,
      incomeCategories: incomeCategories.length,
      expenseCategories: expenseCategories.length,
      defaultCategories: allCategories.where((c) => c.isDefault).length,
      customCategories: allCategories.where((c) => !c.isDefault).length,
      activeCategories: allCategories.where((c) => c.isActive).length,
    );
  }

  // Validate category type
  bool _isValidCategoryType(String type) {
    return type == 'income' || type == 'expense';
  }

  // Check if category can be safely deleted (no transactions)
  Future<bool> _canDeleteCategory(int categoryId) async {
    // This would check if category is used by any transactions
    // For now, returning true - this should be implemented with transaction queries
    return true;
  }

  // Get valid category types
  List<String> getValidCategoryTypes() {
    return ['income', 'expense'];
  }

  // Get category type display names
  Map<String, String> getCategoryTypeDisplayNames() {
    return {
      'income': 'Income',
      'expense': 'Expense',
    };
  }

  // Get default icons for categories (could be moved to a constants file)
  Map<String, String> getDefaultCategoryIcons() {
    return {
      // Expense category icons
      'Food & Dining': '🍽️',
      'Groceries': '🛒',
      'Transportation': '🚗',
      'Shopping': '🛍️',
      'Entertainment': '🎬',
      'Bills & Utilities': '💡',
      'Healthcare': '⚕️',
      'Education': '📚',
      'Travel': '✈️',
      'Personal Care': '💄',
      'Home & Garden': '🏠',
      'Gifts & Donations': '🎁',
      
      // Income category icons
      'Salary': '💰',
      'Business': '💼',
      'Investment': '📈',
      'Rental': '🏠',
      'Freelance': '💻',
      'Gift': '🎁',
      
      // Generic
      'Other': '📝',
    };
  }
}

// Data classes for category statistics and usage
class CategoryUsageStats {
  final int categoryId;
  final int transactionCount;
  final double totalAmount;
  final double averageAmount;
  final DateTime? lastUsed;

  CategoryUsageStats({
    required this.categoryId,
    required this.transactionCount,
    required this.totalAmount,
    required this.averageAmount,
    this.lastUsed,
  });

  @override
  String toString() {
    return 'CategoryUsageStats(categoryId: $categoryId, transactionCount: $transactionCount, '
           'totalAmount: $totalAmount, averageAmount: $averageAmount, lastUsed: $lastUsed)';
  }
}

class CategoryWithUsage {
  final Category category;
  final CategoryUsageStats usage;

  CategoryWithUsage({
    required this.category,
    required this.usage,
  });

  @override
  String toString() {
    return 'CategoryWithUsage(category: ${category.name}, usage: ${usage.transactionCount} transactions)';
  }
}

class CategorySummary {
  final int totalCategories;
  final int incomeCategories;
  final int expenseCategories;
  final int defaultCategories;
  final int customCategories;
  final int activeCategories;

  CategorySummary({
    required this.totalCategories,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.defaultCategories,
    required this.customCategories,
    required this.activeCategories,
  });

  @override
  String toString() {
    return 'CategorySummary(total: $totalCategories, income: $incomeCategories, '
           'expense: $expenseCategories, default: $defaultCategories, custom: $customCategories, '
           'active: $activeCategories)';
  }
}