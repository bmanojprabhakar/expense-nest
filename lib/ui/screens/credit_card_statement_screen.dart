import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../widgets/month_navigation.dart';
import '../widgets/summary_card.dart';
import '../widgets/daily_transaction_group.dart';
import '../../data/models/account.dart';
import '../../providers/transaction_providers.dart';

// Providers for credit card statement
final statementMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());
final statementAccountProvider = StateProvider<Account?>((ref) => null);

// Provider for credit card statement transactions
final statementTransactionsProvider = FutureProvider<List<TransactionWithDetails>>((ref) async {
  final selectedMonth = ref.watch(statementMonthProvider);
  final account = ref.watch(statementAccountProvider);
  
  if (account == null || account.statementDay == null) return [];
  
  final transactionService = ref.read(transactionServiceProvider);
  
  // Calculate statement period
  final period = _getStatementPeriod(account, selectedMonth);
  
  // Get all transactions for this account within the statement period
  final allTransactions = await transactionService.getTransactionsByDateRange(
    accountId: account.id!,
    startDate: period.from,
    endDate: period.to,
  );
  
  return allTransactions;
});

// Provider for statement summary
final statementSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final transactions = await ref.watch(statementTransactionsProvider.future);
  
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

class CreditCardStatementScreen extends ConsumerStatefulWidget {
  final Account account;

  const CreditCardStatementScreen({
    super.key,
    required this.account,
  });

  @override
  ConsumerState<CreditCardStatementScreen> createState() => _CreditCardStatementScreenState();
}

class _CreditCardStatementScreenState extends ConsumerState<CreditCardStatementScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statementAccountProvider.notifier).state = widget.account;
      ref.read(statementMonthProvider.notifier).state = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(statementMonthProvider);
    final summaryAsync = ref.watch(statementSummaryProvider);
    final transactionsAsync = ref.watch(statementTransactionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.account.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Credit Card Statement',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Statement period info
            _buildStatementPeriodHeader(selectedMonth),
            
            // Month navigation
            MonthNavigation(
              selectedMonth: selectedMonth,
              onMonthChanged: (month) {
                ref.read(statementMonthProvider.notifier).state = month;
              },
            ),

            // Summary card
            summaryAsync.when(
              data: (summary) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SummaryCard(
                  income: summary['income'] ?? 0.0,
                  expense: summary['expense'] ?? 0.0,
                  total: summary['total'] ?? 0.0,
                  showStatementInfo: true,
                ),
              ),
              loading: () => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const SummaryCard(
                  income: 0.0,
                  expense: 0.0,
                  total: 0.0,
                ),
              ),
              error: (error, stack) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const SummaryCard(
                  income: 0.0,
                  expense: 0.0,
                  total: 0.0,
                ),
              ),
            ),

            // Transaction list
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) => _buildTransactionsList(transactions, selectedMonth),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.activeTabColor),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.expenseColor,
                        size: 48,
                      ),
                      AppTheme.verticalSpaceMedium,
                      Text(
                        'Failed to load statement',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      AppTheme.verticalSpaceSmall,
                      Text(
                        error.toString(),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementPeriodHeader(DateTime selectedMonth) {
    final period = _getStatementPeriod(widget.account, selectedMonth);
    final fromStr = '${period.from.day}/${period.from.month}/${period.from.year}';
    final toStr = '${period.to.day}/${period.to.month}/${period.to.year}';
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.activeTabColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppTheme.activeTabColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statement Period',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$fromStr - $toStr',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.account.gracePeriodDays != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Due: ${_getPaymentDueDate(period.to)}',
                    style: const TextStyle(
                      color: AppTheme.expenseColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionWithDetails> transactions, DateTime selectedMonth) {
    if (transactions.isEmpty) {
      final period = _getStatementPeriod(widget.account, selectedMonth);
      final fromStr = '${period.from.day}/${period.from.month}';
      final toStr = '${period.to.day}/${period.to.month}';
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_outlined,
              color: AppTheme.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions found',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No activity during $fromStr - $toStr',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = <String, List<TransactionWithDetails>>{};
    for (final transaction in transactions) {
      final dateKey = _formatDateKey(transaction.transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []);
      groupedTransactions[dateKey]!.add(transaction);
    }

    // Sort dates in descending order (newest first)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayTransactions = groupedTransactions[dateKey]!;
        
        // Calculate daily total
        double dailyTotal = 0.0;
        for (final t in dayTransactions) {
          final amount = t.category?.type == 'income' 
              ? t.transaction.amount 
              : -t.transaction.amount;
          dailyTotal += amount;
        }

        final date = DateTime.parse(dateKey);
        return DailyTransactionGroup(
          date: date,
          dayName: _getDayName(date.weekday),
          totalAmount: dailyTotal,
          transactions: dayTransactions,
        );
      },
    );
  }

  String _getPaymentDueDate(DateTime statementDate) {
    if (widget.account.gracePeriodDays == null) return 'Not set';
    
    final dueDate = statementDate.add(Duration(days: widget.account.gracePeriodDays!));
    return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}

/// Get the statement period (from and to dates) for the given month
({DateTime from, DateTime to}) _getStatementPeriod(Account account, DateTime currentDate) {
  final statementDay = account.statementDay!;
  
  // Current month's statement date
  final currentStatementDate = DateTime(currentDate.year, currentDate.month, statementDay);
  
  // Previous month's statement date + 1 day is the start of the period
  final previousMonth = DateTime(currentDate.year, currentDate.month - 1, statementDay);
  final periodStart = previousMonth.add(const Duration(days: 1));
  
  return (from: periodStart, to: currentStatementDate);
}