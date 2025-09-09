import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../widgets/period_dropdown.dart';
import '../widgets/stats_pie_chart.dart';
import '../widgets/category_stats_list.dart';
import '../../providers/stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedStatsPeriodProvider);
    final selectedDate = ref.watch(selectedStatsDateProvider);
    final periodLabel = ref.watch(periodLabelProvider);
    final selectedTab = ref.watch(selectedStatsTabProvider);
    final categoryStatsAsync = ref.watch(categoryStatsProvider);
    final totalAmountAsync = ref.watch(totalAmountProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with account icon and title (matching transaction screen)
            _buildHeader(context),
            
            // Period selection dropdown
            PeriodDropdown(
              selectedPeriod: selectedPeriod,
              periodLabel: periodLabel,
              currentDate: selectedDate,
              onPeriodChanged: (period) {
                ref.read(selectedStatsPeriodProvider.notifier).state = period;
              },
              onDateChanged: (date) {
                ref.read(selectedStatsDateProvider.notifier).state = date;
              },
            ),
            
            // Income/Expense Tabs
            _buildTabBar(context, ref, selectedTab),
            
            // Content area
            Expanded(
              child: categoryStatsAsync.when(
                data: (categoryStats) => totalAmountAsync.when(
                  data: (totalAmount) => _buildContent(
                    context,
                    ref,
                    categoryStats,
                    totalAmount,
                    selectedTab,
                  ),
                  loading: () => _buildLoadingState(),
                  error: (error, stack) => _buildErrorState(error),
                ),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Account/Wallet icon (same as transaction screen)
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pie_chart,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ),
          
          // Title
          Text(
            'Stats',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          // Spacer for symmetry
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref, String selectedTab) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedStatsTabProvider.notifier).state = 'expenses';
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: selectedTab == 'expenses' 
                      ? AppTheme.primaryBackground 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Text(
                  'Expenses',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedTab == 'expenses' 
                        ? AppTheme.textPrimary 
                        : AppTheme.textSecondary,
                    fontWeight: selectedTab == 'expenses' 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedStatsTabProvider.notifier).state = 'income';
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: selectedTab == 'income' 
                      ? AppTheme.primaryBackground 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Text(
                  'Income',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedTab == 'income' 
                        ? AppTheme.textPrimary 
                        : AppTheme.textSecondary,
                    fontWeight: selectedTab == 'income' 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<CategoryStats> categoryStats,
    double totalAmount,
    String selectedTab,
  ) {
    if (categoryStats.isEmpty) {
      return _buildEmptyState(selectedTab);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Pie Chart
          StatsPieChart(
            categoryStats: categoryStats,
            totalAmount: totalAmount,
            isIncome: selectedTab == 'income',
          ),
          
          AppTheme.verticalSpaceLarge,
          
          // Category List with percentages
          CategoryStatsList(
            categoryStats: categoryStats,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.activeTabColor),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
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
            'Failed to load stats',
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
    );
  }

  Widget _buildEmptyState(String selectedTab) {
    final isIncome = selectedTab == 'income';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            color: AppTheme.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${isIncome ? 'income' : 'expense'} data',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some ${isIncome ? 'income' : 'expenses'} to see stats',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}