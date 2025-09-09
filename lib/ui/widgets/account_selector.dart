import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../screens/add_transaction_screen.dart';
import '../../providers/account_providers.dart';

class AccountSelector extends ConsumerWidget {
  const AccountSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAccount = ref.watch(selectedAccountProvider);
    final leafAccountsAsync = ref.watch(leafAccountsProvider);
    final accountPathsAsync = ref.watch(accountPathsProvider);
    
    return leafAccountsAsync.when(
      data: (accounts) => accountPathsAsync.when(
        data: (paths) => _buildAccountSelector(context, ref, accounts, paths, selectedAccount),
        loading: () => _buildLoadingSelector(context),
        error: (error, stack) => _buildErrorSelector(context, error),
      ),
      loading: () => _buildLoadingSelector(context),
      error: (error, stack) => _buildErrorSelector(context, error),
    );
  }

  Widget _buildAccountSelector(BuildContext context, WidgetRef ref, List<Account> accounts, Map<int, List<String>> accountPaths, int? selectedAccount) {
    final selectedAccountItem = selectedAccount != null 
        ? accounts.where((a) => a.id == selectedAccount).isNotEmpty 
            ? accounts.where((a) => a.id == selectedAccount).first 
            : null
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        AppTheme.verticalSpaceSmall,
        InkWell(
          onTap: () {
            _showAccountPicker(context, ref, accounts, accountPaths);
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
                if (selectedAccountItem != null) ...[
                  Icon(
                    _getAccountIcon(selectedAccountItem.legacyType),
                    color: AppTheme.textSecondary,
                  ),
                  AppTheme.horizontalSpaceMedium,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedAccountItem.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        if (selectedAccountItem.id != null && accountPaths[selectedAccountItem.id!] != null) ...[
                          Text(
                            _formatAccountPath(accountPaths[selectedAccountItem.id!]!),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        Text(
                          AppTheme.formatCurrency(selectedAccountItem.balance, showSign: false),
                          style: TextStyle(
                            color: AppTheme.getAmountColor(selectedAccountItem.balance),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.account_balance_wallet, color: AppTheme.textSecondary),
                  AppTheme.horizontalSpaceMedium,
                  const Expanded(
                    child: Text(
                      'Select an account',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
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
          'Account',
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
                'Loading accounts...',
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
          'Account',
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
                  'Failed to load accounts',
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

  void _showAccountPicker(BuildContext context, WidgetRef ref, List<Account> accounts, Map<int, List<String>> accountPaths) {
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
                'Select Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              AppTheme.verticalSpaceMedium,
              
              // Account list
              Expanded(
                child: ListView.builder(
                  shrinkWrap: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final isSelected = ref.read(selectedAccountProvider) == account.id;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedAccountProvider.notifier).state = account.id;
                          Navigator.of(context).pop();
                        },
                        borderRadius: AppTheme.cardBorderRadius,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.activeTabColor.withValues(alpha: 0.1) : AppTheme.cardBackground,
                            borderRadius: AppTheme.cardBorderRadius,
                            border: Border.all(
                              color: isSelected ? AppTheme.activeTabColor : AppTheme.dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getAccountIcon(account.legacyType),
                                color: isSelected ? AppTheme.activeTabColor : AppTheme.textSecondary,
                              ),
                              AppTheme.horizontalSpaceMedium,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.name,
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    if (account.id != null && accountPaths[account.id!] != null) ...[
                                      Text(
                                        _formatAccountPath(accountPaths[account.id!]!),
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        _getAccountTypeDisplay(account.legacyType),
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Balance',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    AppTheme.formatCurrency(account.balance, showSign: false),
                                    style: TextStyle(
                                      color: AppTheme.getAmountColor(account.balance),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'cash':
        return Icons.account_balance_wallet;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _getAccountTypeDisplay(String type) {
    switch (type) {
      case 'bank':
        return 'Bank Account';
      case 'savings':
        return 'Savings Account';
      case 'cash':
        return 'Cash';
      case 'credit_card':
        return 'Credit Card';
      default:
        return type;
    }
  }

  String _formatAccountPath(List<String> path) {
    if (path.length <= 1) {
      return ''; // Don't show path for single level accounts
    }
    // Show all parent levels except the account name itself
    final parents = path.take(path.length - 1).toList();
    return parents.join(' > ');
  }
}

