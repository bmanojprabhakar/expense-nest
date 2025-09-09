import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/transaction_service.dart';
import '../services/account_service.dart';
import '../data/database/database_helper.dart';

// Export types that consumers need
export '../services/transaction_service.dart';

// Provider for transaction service
final transactionServiceProvider = Provider<TransactionService>((ref) {
  final dbHelper = DatabaseHelper();
  final accountService = AccountService(dbHelper);
  return TransactionService(dbHelper, accountService);
});

// Provider for current selected month
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider for current selected tab
final selectedTabProvider = StateProvider<String>((ref) => 'Daily');

// Provider for monthly transactions
final monthlyTransactionsProvider = FutureProvider<List<TransactionWithDetails>>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final transactionService = ref.read(transactionServiceProvider);
  
  return transactionService.getTransactionsForMonth(
    selectedMonth.year,
    selectedMonth.month,
  );
});

// Provider for monthly summary
final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final transactions = await ref.watch(monthlyTransactionsProvider.future);
  
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  
  for (final transaction in transactions) {
    if (transaction.category?.type == 'income') {
      totalIncome += transaction.transaction.amount;
    } else {
      totalExpense += transaction.transaction.amount;
    }
  }
  
  return {
    'income': totalIncome,
    'expense': totalExpense,
    'total': totalIncome - totalExpense,
  };
});

// Data class for daily summary
class DailySummary {
  final DateTime date;
  final double income;
  final double expense;
  final double total;
  final int transactionCount;

  DailySummary({
    required this.date,
    required this.income,
    required this.expense,
    required this.total,
    required this.transactionCount,
  });

  bool get hasTransactions => transactionCount > 0;
}

// Provider for daily summaries (for calendar view)
final dailySummariesProvider = FutureProvider<Map<int, DailySummary>>((ref) async {
  final transactions = await ref.watch(monthlyTransactionsProvider.future);
  final selectedMonth = ref.watch(selectedMonthProvider);
  
  final dailySummaries = <int, DailySummary>{};
  
  // Initialize all days of the month
  final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(selectedMonth.year, selectedMonth.month, day);
    dailySummaries[day] = DailySummary(
      date: date,
      income: 0.0,
      expense: 0.0,
      total: 0.0,
      transactionCount: 0,
    );
  }
  
  // Calculate actual values from transactions
  for (final transaction in transactions) {
    final day = transaction.transaction.date.day;
    final existing = dailySummaries[day]!;
    
    final isIncome = transaction.category?.type == 'income';
    final amount = transaction.transaction.amount;
    
    dailySummaries[day] = DailySummary(
      date: existing.date,
      income: existing.income + (isIncome ? amount : 0),
      expense: existing.expense + (isIncome ? 0 : amount),
      total: existing.total + (isIncome ? amount : -amount),
      transactionCount: existing.transactionCount + 1,
    );
  }
  
  return dailySummaries;
});