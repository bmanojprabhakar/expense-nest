import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../screens/edit_transaction_screen.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';

class DailyTransactionGroup extends StatelessWidget {
  final DateTime date;
  final String dayName;
  final double totalAmount;
  final List<TransactionWithDetails> transactions;

  const DailyTransactionGroup({
    super.key,
    required this.date,
    required this.dayName,
    required this.totalAmount,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header with total
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    date.day.toString(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppTheme.horizontalSpaceSmall,
                  Text(
                    dayName,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                AppTheme.formatCurrency(totalAmount),
                style: TextStyle(
                  color: AppTheme.getAmountColor(totalAmount),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Transaction cards
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.accentBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: transactions.asMap().entries.map((entry) {
              final index = entry.key;
              final transaction = entry.value;
              final isLast = index == transactions.length - 1;
              
              return _TransactionCard(
                key: Key('transaction_card_${transaction.transaction.id}'),
                transaction: transaction,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),

        AppTheme.verticalSpaceMedium,
      ],
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  final TransactionWithDetails transaction;
  final bool isLast;

  const _TransactionCard({
    super.key,
    required this.transaction,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.category?.type == 'income';
    final amount = isIncome ? transaction.transaction.amount : -transaction.transaction.amount;
    final categoryIcon = _getCategoryIcon(transaction.category?.icon, transaction.category?.type);
    
    return Dismissible(
      key: Key('transaction_${transaction.transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: AppTheme.textPrimary,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog and handle deletion
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title: const Text(
                'Delete Transaction',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: const Text(
                'Are you sure you want to delete this transaction?',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ),
              ],
            );
          },
        ) ?? false;
        
        if (shouldDelete) {
          // Perform actual deletion
          return await _deleteTransaction(context, ref, this.transaction);
        }
        
        return false;
      },
      child: InkWell(
        onTap: () {
          // Navigate to edit transaction screen
          print('DEBUG: Clicked on transaction ID: ${this.transaction.transaction.id}, Amount: ${this.transaction.transaction.amount}');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditTransactionScreen(
                transactionWithDetails: this.transaction,
              ),
            ),
          ).then((result) {
            // Refresh data if transaction was updated successfully
            print('DEBUG: Navigation returned with result: $result');
            if (result == true) {
              print('DEBUG: Refreshing data after successful transaction update');
              ref.invalidate(leafAccountsProvider);
              ref.invalidate(monthlyTransactionsProvider);
              ref.invalidate(monthlySummaryProvider);
              ref.invalidate(dailySummariesProvider);
              
              // Also invalidate account screen providers to refresh balances
              ref.invalidate(accountsTreeProvider);
              ref.invalidate(assetsLiabilitiesProvider);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: isLast ? null : const Border(
              bottom: BorderSide(color: Colors.transparent, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Icon
              categoryIcon,
              
              AppTheme.horizontalSpaceMedium,
              
              // Title and account
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (transaction.transaction.note?.isNotEmpty == true)
                      Text(
                        transaction.transaction.note!,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      transaction.account?.name ?? 'Unknown Account',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Text(
                AppTheme.formatCurrency(amount, showSign: false),
                style: TextStyle(
                  color: isIncome 
                      ? AppTheme.incomeColor 
                      : AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String? iconString, String? categoryType) {
    if (iconString != null && iconString.isNotEmpty) {
      // For emoji icons, display them directly
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppTheme.iconSecondary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            iconString,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      );
    }
    
    // Fallback to material icons
    IconData iconData;
    switch (categoryType) {
      case 'income':
        iconData = Icons.trending_up;
        break;
      case 'expense':
        iconData = Icons.trending_down;
        break;
      default:
        iconData = Icons.category;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppTheme.iconSecondary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: AppTheme.textPrimary,
        size: 20,
      ),
    );
  }

  Future<bool> _deleteTransaction(BuildContext context, WidgetRef ref, TransactionWithDetails transaction) async {
    try {
      // Get transaction service from provider
      final transactionService = ref.read(transactionServiceProvider);
      
      // Delete transaction
      await transactionService.deleteTransaction(transaction.transaction.id!);
      
      // Refresh providers to update UI immediately
      ref.invalidate(leafAccountsProvider);
      ref.invalidate(monthlyTransactionsProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(dailySummariesProvider);
      
      // Also invalidate account screen providers to refresh balances
      ref.invalidate(accountsTreeProvider);
      ref.invalidate(assetsLiabilitiesProvider);
      
      // Show success message only if the context is still valid
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully!'),
            backgroundColor: AppTheme.activeTabColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      return true; // Return true on successful deletion
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete transaction: ${e.toString()}'),
          backgroundColor: AppTheme.expenseColor,
        ),
      );
      return false; // Return false on error
    }
  }
}