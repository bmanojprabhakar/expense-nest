import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../providers/transaction_providers.dart';

class TransactionCalendar extends ConsumerWidget {
  const TransactionCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final dailySummariesAsync = ref.watch(dailySummariesProvider);

    return dailySummariesAsync.when(
      data: (dailySummaries) => _buildCalendar(context, selectedMonth, dailySummaries),
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
              'Failed to load calendar',
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
    );
  }

  Widget _buildCalendar(BuildContext context, DateTime selectedMonth, Map<int, DailySummary> dailySummaries) {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Calendar header (weekday names)
          _buildCalendarHeader(),
          
          AppTheme.verticalSpaceMedium,
          
          // Full-screen calendar grid
          Expanded(
            child: _buildFullScreenCalendarGrid(firstWeekday, daysInMonth, dailySummaries),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: weekdays.map((day) => Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildFullScreenCalendarGrid(int firstWeekday, int daysInMonth, Map<int, DailySummary> dailySummaries) {
    final totalWeeks = ((firstWeekday - 1 + daysInMonth) / 7).ceil();
    
    return Column(
      children: List.generate(totalWeeks, (weekIndex) {
        return Expanded(
          child: Row(
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              final dayNumber = cellIndex - firstWeekday + 2;
              
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                // Empty cell for days outside current month
                return Expanded(child: Container());
              }
              
              final summary = dailySummaries[dayNumber]!;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(1),
                  child: _buildFullScreenCalendarCell(dayNumber, summary),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildFullScreenCalendarCell(int dayNumber, DailySummary summary) {
    final hasTransactions = summary.hasTransactions;
    final isToday = _isToday(summary.date);
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: isToday 
            ? Border.all(color: AppTheme.activeTabColor, width: 2)
            : Border.all(color: AppTheme.textSecondary.withAlpha(30), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day number (top-left)
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                dayNumber.toString(),
                style: TextStyle(
                  color: isToday 
                      ? AppTheme.activeTabColor
                      : hasTransactions 
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            
            // Spacer to push amounts to bottom
            const Spacer(),
            
            // Income and expense amounts (bottom-right)
            if (hasTransactions) ...[
              Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Income amount
                    if (summary.income > 0)
                      Text(
                        _formatCurrencyCompact(summary.income),
                        style: const TextStyle(
                          color: AppTheme.incomeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // Small spacing between income and expense
                    if (summary.income > 0 && summary.expense > 0)
                      const SizedBox(height: 1),
                    
                    // Expense amount
                    if (summary.expense > 0)
                      Text(
                        _formatCurrencyCompact(summary.expense),
                        style: const TextStyle(
                          color: AppTheme.expenseColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ] else if (isToday) ...[
              // Show "Today" indicator for current day even with no transactions
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.activeTabColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Compact currency formatter for calendar cells (integers only)
  static String _formatCurrencyCompact(double amount) {
    final roundedAmount = amount.round();
    
    // Handle large numbers with K suffix for thousands
    if (roundedAmount >= 100000) {
      return '₹${(roundedAmount / 100000).toStringAsFixed(1)}L';
    } else if (roundedAmount >= 1000) {
      return '₹${(roundedAmount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹$roundedAmount';
    }
  }
}

// Calendar summary header showing monthly totals
class CalendarSummaryHeader extends ConsumerWidget {
  const CalendarSummaryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return summaryAsync.when(
      data: (summary) => _buildSummaryHeader(summary),
      loading: () => _buildLoadingSummary(),
      error: (error, stack) => _buildErrorSummary(),
    );
  }

  Widget _buildSummaryHeader(Map<String, double> summary) {
    final income = summary['income'] ?? 0.0;
    final expense = summary['expense'] ?? 0.0;
    final total = summary['total'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem('Income', income, AppTheme.incomeColor),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.textSecondary.withAlpha(51),
          ),
          Expanded(
            child: _buildSummaryItem('Expense', expense, AppTheme.expenseColor),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.textSecondary.withAlpha(51),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Net', 
              total, 
              total >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        AppTheme.verticalSpaceSmall,
        Text(
          TransactionCalendar._formatCurrencyCompact(amount),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.activeTabColor),
          ),
        )),
      ),
    );
  }

  Widget _buildErrorSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
      ),
      child: const Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.expenseColor,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Failed to load summary',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}