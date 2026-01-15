import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'add_account_screen.dart';
import 'edit_account_screen.dart';
import 'credit_card_statement_screen.dart';
import '../widgets/hierarchical_account_tree.dart';
import '../widgets/month_navigation.dart';
import '../widgets/tab_bar_widget.dart';
import '../../providers/account_providers.dart';
import '../../services/account_service.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(accountsSelectedMonthProvider);
    final selectedTab = ref.watch(accountsSelectedTabProvider);
    
    // Use different providers based on selected tab
    final accountsTreeAsync = selectedTab == 'All Accounts' 
        ? ref.watch(accountsTreeProvider)  // Current data for All Accounts
        : ref.watch(monthlyAccountsTreeProvider); // Monthly data for Credit Cards
    
    final assetsLiabilitiesAsync = selectedTab == 'All Accounts'
        ? ref.watch(assetsLiabilitiesProvider)  // Current assets/liabilities
        : ref.watch(creditCardSummaryProvider); // Billed/unbilled for Credit Cards

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with account icon and title
            _buildHeader(context, ref),
            
            // Month navigation (only for Credit Cards tab)
            if (selectedTab == 'Credit Cards') ...[
              MonthNavigation(
                selectedMonth: selectedMonth,
                onMonthChanged: (month) {
                  ref.read(accountsSelectedMonthProvider.notifier).state = month;
                },
              ),
            ],
            
            // Tab bar (All Accounts, Credit Cards)
            TabBarWidget(
              selectedTab: selectedTab,
              tabs: const ['All Accounts', 'Credit Cards'],
              onTabChanged: (tab) {
                ref.read(accountsSelectedTabProvider.notifier).state = tab;
                // Refresh providers when switching tabs to ensure data is current
                if (tab == 'Credit Cards') {
                  ref.invalidate(creditCardsProvider);
                  ref.invalidate(monthlyAccountsTreeProvider);
                  ref.invalidate(creditCardSummaryProvider);
                } else {
                  ref.invalidate(accountsTreeProvider);
                  ref.invalidate(assetsLiabilitiesProvider);
                }
              },
            ),

            // Summary section (Assets/Liabilities or Billed/Unbilled based on tab)
            assetsLiabilitiesAsync.when(
              data: (summary) => selectedTab == 'All Accounts'
                  ? _buildAssetsSummarySection(summary as AssetLiabilityBreakdown)
                  : _buildCreditCardSummarySection(summary as CreditCardSummary),
              loading: () => _buildLoadingSummary(selectedTab),
              error: (error, stack) => _buildErrorSummary(),
            ),

            // Content area based on selected tab
            Expanded(
              child: selectedTab == 'All Accounts'
                  ? _buildAllAccountsTab(context, ref, accountsTreeAsync)
                  : _buildCreditCardsTab(ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Account/Wallet icon (smaller)
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: AppTheme.textPrimary,
              size: 18,
            ),
          ),
          
          // Title (smaller font)
          Text(
            'Accounts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          // Add Account button (smaller)
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddAccountScreen(),
                  ),
                ).then((result) {
                  // Refresh data if account was saved successfully
                  if (result == true) {
                    ref.invalidate(accountsTreeProvider);
                    ref.invalidate(accountSummaryProvider);
                    ref.invalidate(assetsLiabilitiesProvider);
                    ref.invalidate(creditCardsProvider);
                    ref.invalidate(creditCardSummaryProvider);
                  }
                });
              },
              icon: const Icon(
                Icons.add,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAccountsTab(BuildContext context, WidgetRef ref, AsyncValue<List<AccountNode>> accountsTreeAsync) {
    return accountsTreeAsync.when(
      data: (accountTree) => accountTree.isEmpty 
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: HierarchicalAccountTree(
                    accountTree: accountTree,
                    showBalances: true,
                    onAccountTap: (node) {
                      // Only allow editing leaf accounts (actual accounts)
                      if (node.isLeaf) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditAccountScreen(account: node.account),
                          ),
                        ).then((result) {
                          // Refresh data if account was updated successfully
                          if (result == true) {
                            ref.invalidate(accountsTreeProvider);
                            ref.invalidate(accountSummaryProvider);
                            ref.invalidate(assetsLiabilitiesProvider);
                            ref.invalidate(creditCardsProvider);
                            ref.invalidate(creditCardSummaryProvider);
                          }
                        });
                      } else {
                        // For parent accounts, show info
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${node.account.name}" is a parent account. Tap on leaf accounts to edit them.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
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
              'Failed to load accounts',
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

  Widget _buildAssetsSummarySection(AssetLiabilityBreakdown breakdown) {
    final assets = breakdown.assets;
    final liabilities = breakdown.liabilities;
    final total = breakdown.netWorth;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Assets',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.formatCurrency(assets, showSign: false),
                  style: const TextStyle(
                    color: AppTheme.incomeColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Liabilities',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.formatCurrency(liabilities, showSign: false),
                  style: const TextStyle(
                    color: AppTheme.expenseColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Net Worth',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.formatCurrency(total, showSign: false),
                  style: TextStyle(
                    color: total >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardSummarySection(CreditCardSummary summary) {
    final billed = summary.billedAmount;
    final unbilled = summary.unbilledAmount;
    final total = summary.totalAmount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Billed',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.formatCurrency(billed, showSign: false),
                  style: const TextStyle(
                    color: AppTheme.expenseColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Unbilled',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.formatCurrency(unbilled, showSign: false),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Total',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.formatCurrency(total, showSign: false),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSummary(String selectedTab) {
    final labels = selectedTab == 'All Accounts' 
        ? ['Assets', 'Liabilities', 'Net Worth']
        : ['Billed', 'Unbilled', 'Total'];
        
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
      ),
      child: Row(
        children: labels.map((label) => Expanded(
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.activeTabColor),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildErrorSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.expenseColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          const Text(
            'Failed to load account summary',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: AppTheme.textSecondary,
            size: 64,
          ),
          AppTheme.verticalSpaceMedium,
          const Text(
            'No accounts yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppTheme.verticalSpaceSmall,
          const Text(
            'Tap + to add your first account',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardsTab(WidgetRef ref) {
    final creditCardsAsync = ref.watch(creditCardsProvider);
    
    return creditCardsAsync.when(
      data: (creditCards) => creditCards.isEmpty 
          ? _buildNoCreditCardsState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: creditCards.length,
              itemBuilder: (context, index) {
                final account = creditCards[index];
                return _buildCreditCardItem(context, ref, account);
              },
            ),
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
              'Failed to load credit cards',
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
  
  Widget _buildNoCreditCardsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.credit_card_off,
            color: AppTheme.textSecondary,
            size: 64,
          ),
          AppTheme.verticalSpaceMedium,
          const Text(
            'No credit cards yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppTheme.verticalSpaceSmall,
          const Text(
            'Add a credit card account to see statements',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardItem(BuildContext context, WidgetRef ref, Account account) {
    final currentDate = DateTime.now();
    final canShowStatement = _canShowStatement(account, currentDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: InkWell(
        onTap: () => _onCreditCardTap(context, ref, account, canShowStatement),
        onLongPress: () => _onCreditCardEdit(context, ref, account),
        borderRadius: AppTheme.cardBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.activeTabColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: AppTheme.activeTabColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Balance: ${AppTheme.formatCurrency(account.balance)}',
                          style: TextStyle(
                            color: account.balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    canShowStatement ? Icons.receipt_long : Icons.schedule,
                    color: canShowStatement ? AppTheme.activeTabColor : AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCardInfo(
                      'Statement Day',
                      account.statementDay?.toString() ?? 'Not set',
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCardInfo(
                      'Grace Period',
                      account.gracePeriodDays != null ? '${account.gracePeriodDays} days' : 'Not set',
                      Icons.access_time,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: canShowStatement 
                      ? AppTheme.activeTabColor.withValues(alpha: 0.1)
                      : AppTheme.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              canShowStatement ? Icons.visibility : Icons.schedule,
                              size: 16,
                              color: canShowStatement ? AppTheme.activeTabColor : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              canShowStatement ? 'Tap to view statement' : 'Bill yet to be generated',
                              style: TextStyle(
                                color: canShowStatement ? AppTheme.activeTabColor : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          // children: [
                          //   Icon(
                          //     Icons.edit,
                          //     size: 12,
                          //     color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          //   ),
                          //   const SizedBox(width: 4),
                          //   Text(
                          //     'Long press to edit',
                          //     style: TextStyle(
                          //       color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          //       fontSize: 10,
                          //       fontStyle: FontStyle.italic,
                          //     ),
                          //   ),
                          // ],
                        ),
                      ],
                    ),
                    if (canShowStatement) ...[
                      const SizedBox(height: 4),
                      _buildStatementPeriodInfo(account, currentDate),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  bool _canShowStatement(Account account, DateTime currentDate) {
    if (account.statementDay == null) return false;
    
    // Get the statement date for current month
    final currentMonthStatementDate = DateTime(currentDate.year, currentDate.month, account.statementDay!);
    
    // If current date is on or after this month's statement date, we can show the statement
    // The statement will show transactions from previous month's statement date + 1 to current month's statement date
    return currentDate.isAfter(currentMonthStatementDate) || currentDate.isAtSameMomentAs(currentMonthStatementDate);
  }
  
  /// Get the statement period (from and to dates) for the current statement
  ({DateTime from, DateTime to}) _getStatementPeriod(Account account, DateTime currentDate) {
    final statementDay = account.statementDay!;
    
    // Current month's statement date
    final currentStatementDate = DateTime(currentDate.year, currentDate.month, statementDay);
    
    // Previous month's statement date + 1 day is the start of the period
    final previousMonth = DateTime(currentDate.year, currentDate.month - 1, statementDay);
    final periodStart = previousMonth.add(const Duration(days: 1));
    
    return (from: periodStart, to: currentStatementDate);
  }
  
  Widget _buildStatementPeriodInfo(Account account, DateTime currentDate) {
    final period = _getStatementPeriod(account, currentDate);
    final fromStr = '${period.from.day}/${period.from.month}';
    final toStr = '${period.to.day}/${period.to.month}';
    
    return Text(
      'Period: $fromStr - $toStr',
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 10,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  void _onCreditCardTap(BuildContext context, WidgetRef ref, Account account, bool canShowStatement) {
    if (canShowStatement) {
      // Directly navigate to credit card statement screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreditCardStatementScreen(account: account),
        ),
      );
    } else {
      // Show info about when statement will be available
      final nextStatementDate = DateTime(DateTime.now().year, DateTime.now().month, account.statementDay!);
      final nextStr = '${nextStatementDate.day}/${nextStatementDate.month}';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statement will be available on $nextStr'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onCreditCardEdit(BuildContext context, WidgetRef ref, Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditAccountScreen(account: account),
      ),
    ).then((result) {
      // Refresh data if account was updated successfully
      if (result == true) {
        ref.invalidate(creditCardsProvider);
        ref.invalidate(accountsTreeProvider);
        ref.invalidate(assetsLiabilitiesProvider);
        ref.invalidate(creditCardSummaryProvider);
      }
    });
  }
  
  String _getStatementPeriodString(Account account) {
    final period = _getStatementPeriod(account, DateTime.now());
    final fromStr = '${period.from.day}/${period.from.month}';
    final toStr = '${period.to.day}/${period.to.month}';
    return 'Period: $fromStr - $toStr';
  }

}