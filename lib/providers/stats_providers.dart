import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transaction_providers.dart';

// Enum for time period filter
enum StatsPeriod {
  week,
  month,
  year,
}

// Provider for current selected stats period
final selectedStatsPeriodProvider = StateProvider<StatsPeriod>((ref) => StatsPeriod.month);

// Provider for current stats date (base date for calculations)
final selectedStatsDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Data class for category statistics
class CategoryStats {
  final String categoryId;
  final String categoryName;
  final String categoryType;
  final double totalAmount;
  final double percentage;
  final int transactionCount;

  CategoryStats({
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
  });
}

// Provider for stats transactions based on selected period
final statsTransactionsProvider = FutureProvider<List<TransactionWithDetails>>((ref) async {
  final selectedPeriod = ref.watch(selectedStatsPeriodProvider);
  final selectedDate = ref.watch(selectedStatsDateProvider);
  final transactionService = ref.read(transactionServiceProvider);
  
  switch (selectedPeriod) {
    case StatsPeriod.week:
      // Get week's start (Monday) and end (Sunday)
      final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      return transactionService.getTransactionsForDateRange(
        startOfWeek,
        endOfWeek,
      );
      
    case StatsPeriod.month:
      return transactionService.getTransactionsForMonth(
        selectedDate.year,
        selectedDate.month,
      );
      
    case StatsPeriod.year:
      return transactionService.getTransactionsForYear(selectedDate.year);
  }
});

// Provider for selected tab (expense or income)
final selectedStatsTabProvider = StateProvider<String>((ref) => 'expenses');

// Provider for category-wise expense statistics (percentages)
final categoryStatsProvider = FutureProvider<List<CategoryStats>>((ref) async {
  final selectedTab = ref.watch(selectedStatsTabProvider);
  final transactions = await ref.watch(statsTransactionsProvider.future);
  
  // Filter transactions based on selected tab
  final filteredTransactions = transactions.where((t) {
    if (selectedTab == 'income') {
      return t.category?.type == 'income';
    } else {
      return t.category?.type == 'expense' || t.category?.type != 'income';
    }
  }).toList();
  
  if (filteredTransactions.isEmpty) {
    return <CategoryStats>[];
  }
  
  // Group by category and calculate totals
  final categoryTotals = <String, Map<String, dynamic>>{};
  double totalAmount = 0.0;
  
  for (final transaction in filteredTransactions) {
    final categoryId = transaction.category?.id.toString() ?? 'unknown';
    final categoryName = transaction.category?.name ?? 'Unknown';
    final categoryType = transaction.category?.type ?? (selectedTab == 'income' ? 'income' : 'expense');
    final amount = transaction.transaction.amount;
    
    totalAmount += amount;
    
    if (categoryTotals.containsKey(categoryId)) {
      categoryTotals[categoryId]!['amount'] += amount;
      categoryTotals[categoryId]!['count'] += 1;
    } else {
      categoryTotals[categoryId] = {
        'name': categoryName,
        'type': categoryType,
        'amount': amount,
        'count': 1,
      };
    }
  }
  
  // Convert to CategoryStats with percentages
  final categoryStats = categoryTotals.entries.map((entry) {
    final categoryId = entry.key;
    final data = entry.value;
    final amount = data['amount'] as double;
    final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;
    
    return CategoryStats(
      categoryId: categoryId,
      categoryName: data['name'] as String,
      categoryType: data['type'] as String,
      totalAmount: amount,
      percentage: percentage,
      transactionCount: data['count'] as int,
    );
  }).toList();
  
  // Sort by percentage (descending)
  categoryStats.sort((a, b) => b.percentage.compareTo(a.percentage));
  
  return categoryStats;
});

// Provider for total amount for the selected period and tab
final totalAmountProvider = FutureProvider<double>((ref) async {
  final categoryStats = await ref.watch(categoryStatsProvider.future);
  
  return categoryStats.fold<double>(0.0, (sum, category) => sum + category.totalAmount);
});

// Keep the old provider name for backward compatibility
final totalExpensesProvider = totalAmountProvider;

// Provider for period label (e.g., "October 2024", "Week 41, 2024", "2024")
final periodLabelProvider = Provider<String>((ref) {
  final selectedPeriod = ref.watch(selectedStatsPeriodProvider);
  final selectedDate = ref.watch(selectedStatsDateProvider);
  
  switch (selectedPeriod) {
    case StatsPeriod.week:
      // Get week number
      final startOfYear = DateTime(selectedDate.year, 1, 1);
      final weekNumber = ((selectedDate.difference(startOfYear).inDays) / 7).floor() + 1;
      return 'Week $weekNumber, ${selectedDate.year}';
      
    case StatsPeriod.month:
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${monthNames[selectedDate.month - 1]} ${selectedDate.year}';
      
    case StatsPeriod.year:
      return selectedDate.year.toString();
  }
});