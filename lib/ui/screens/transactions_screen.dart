import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../widgets/month_navigation.dart';
import '../widgets/tab_bar_widget.dart';
import '../widgets/summary_card.dart';
import '../widgets/daily_transaction_group.dart';
import '../widgets/transaction_calendar.dart';
import 'add_transaction_screen.dart';
import '../../providers/transaction_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final transactionsAsync = ref.watch(monthlyTransactionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header with account icon and title
                _buildHeader(context),
                
                // Month navigation
                MonthNavigation(
                  selectedMonth: selectedMonth,
                  onMonthChanged: (month) {
                    ref.read(selectedMonthProvider.notifier).state = month;
                  },
                ),
                
                // Tab bar (Daily, Calendar, Monthly, Summary, Description)
                TabBarWidget(
                  selectedTab: selectedTab,
                  onTabChanged: (tab) {
                    ref.read(selectedTabProvider.notifier).state = tab;
                  },
                ),

                // Content area (Calendar or List view based on selected tab)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80), // Space for fixed button
                    child: selectedTab == 'Calendar' 
                        ? _buildCalendarView()
                        : _buildListView(summaryAsync, transactionsAsync),
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed Add Transaction button at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildAddTransactionButton(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        // Calendar-specific summary header
        const CalendarSummaryHeader(),
        
        AppTheme.verticalSpaceMedium,
        
        // Full-screen calendar widget
        const Expanded(
          child: TransactionCalendar(),
        ),
      ],
    );
  }

  Widget _buildListView(AsyncValue<Map<String, double>> summaryAsync, AsyncValue<List<TransactionWithDetails>> transactionsAsync) {
    return Column(
      children: [
        // Summary card for list view
        summaryAsync.when(
          data: (summary) => SummaryCard(
            income: summary['income'] ?? 0.0,
            expense: summary['expense'] ?? 0.0,
            total: summary['total'] ?? 0.0,
          ),
          loading: () => const SummaryCard(
            income: 0.0,
            expense: 0.0,
            total: 0.0,
          ),
          error: (error, stack) => const SummaryCard(
            income: 0.0,
            expense: 0.0,
            total: 0.0,
          ),
        ),

        // Transaction list
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) => _buildTransactionsList(transactions),
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
                    'Failed to load transactions',
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
    );
  }

  Widget _buildTransactionsList(List<TransactionWithDetails> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              color: AppTheme.textSecondary,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to add your first transaction',
              style: TextStyle(
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

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }


  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Account/Wallet icon
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: AppTheme.textPrimary,
              size: 16,
            ),
          ),
          
          // Title
          Text(
            'Transaction',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          // Spacer for symmetry
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildAddTransactionButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryBackground,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                ).then((result) {
                  // Refresh data if transaction was saved successfully
                  if (result == true) {
                    ref.invalidate(monthlyTransactionsProvider);
                    ref.invalidate(monthlySummaryProvider);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.activeTabColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonBorderRadius,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppTheme.textPrimary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add Transaction',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
