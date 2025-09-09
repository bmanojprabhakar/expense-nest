import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../screens/add_transaction_screen.dart';
import '../../services/category_service.dart';
import '../../data/models/category.dart';
import '../../data/database/database_helper.dart';

// Provider for category service
final categoryServiceProvider = Provider<CategoryService>((ref) {
  final dbHelper = DatabaseHelper();
  return CategoryService(dbHelper);
});

// Provider for categories by type
final categoriesProvider = FutureProvider.family<List<Category>, String>((ref, type) async {
  final categoryService = ref.read(categoryServiceProvider);
  if (type == 'expense') {
    return categoryService.getExpenseCategories();
  } else {
    return categoryService.getIncomeCategories();
  }
});

class CategorySelector extends ConsumerWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionType = ref.watch(transactionTypeProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    final categoryType = transactionType == TransactionType.expense ? 'expense' : 'income';
    final categoriesAsync = ref.watch(categoriesProvider(categoryType));
    
    return categoriesAsync.when(
      data: (categories) => _buildCategorySelector(context, ref, categories, selectedCategory),
      loading: () => _buildLoadingSelector(context),
      error: (error, stack) => _buildErrorSelector(context, error),
    );
  }

  Widget _buildCategorySelector(BuildContext context, WidgetRef ref, List<Category> categories, int? selectedCategory) {
    final selectedCategoryItem = selectedCategory != null 
        ? categories.where((c) => c.id == selectedCategory).isNotEmpty 
            ? categories.where((c) => c.id == selectedCategory).first 
            : null
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        AppTheme.verticalSpaceSmall,
        InkWell(
          onTap: () {
            _showCategoryPicker(context, ref, categories);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: AppTheme.cardBorderRadius,
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                if (selectedCategoryItem != null) ...[
                  Text(
                    selectedCategoryItem.icon ?? '📁',
                    style: const TextStyle(fontSize: 24),
                  ),
                  AppTheme.horizontalSpaceMedium,
                  Text(
                    selectedCategoryItem.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.category, color: AppTheme.textSecondary),
                  AppTheme.horizontalSpaceMedium,
                  const Text(
                    'Select a category',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        AppTheme.verticalSpaceSmall,
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: AppTheme.cardBorderRadius,
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondary),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Loading categories...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSelector(BuildContext context, Object error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        AppTheme.verticalSpaceSmall,
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: AppTheme.cardBorderRadius,
            border: Border.all(color: AppTheme.expenseColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.error, color: AppTheme.expenseColor),
              AppTheme.horizontalSpaceMedium,
              const Expanded(
                child: Text(
                  'Failed to load categories',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCategoryPicker(BuildContext context, WidgetRef ref, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AppTheme.verticalSpaceMedium,
              
              // Title
              Text(
                'Select Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              AppTheme.verticalSpaceMedium,
              
              // Category grid
              Expanded(
                child: GridView.builder(
                  shrinkWrap: false,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = ref.read(selectedCategoryProvider) == category.id;
                    
                    return InkWell(
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).state = category.id;
                        Navigator.of(context).pop();
                      },
                      borderRadius: AppTheme.cardBorderRadius,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.activeTabColor : AppTheme.cardBackground,
                          borderRadius: AppTheme.cardBorderRadius,
                          border: Border.all(
                            color: isSelected ? AppTheme.activeTabColor : AppTheme.dividerColor,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category.icon ?? '📁',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                category.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.textPrimary : AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              AppTheme.verticalSpaceMedium,
            ],
          ),
        );
      },
    );
  }
}

