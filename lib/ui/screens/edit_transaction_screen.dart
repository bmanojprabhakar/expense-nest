import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../widgets/category_selector.dart';
import '../widgets/account_selector.dart';
import '../widgets/shared_expense_section.dart';
import 'add_transaction_screen.dart' as add_transaction;
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';

// Provider for the transaction being edited
final editingTransactionProvider = StateProvider<TransactionWithDetails?>((ref) => null);

// Provider for delete confirmation loading
final deletingTransactionProvider = StateProvider<bool>((ref) => false);

class EditTransactionScreen extends ConsumerStatefulWidget {
  final TransactionWithDetails transactionWithDetails;

  const EditTransactionScreen({
    super.key,
    required this.transactionWithDetails,
  });

  @override
  ConsumerState<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _descriptionController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize form controllers with transaction data
    final transaction = widget.transactionWithDetails.transaction;
    final category = widget.transactionWithDetails.category;
    
    print('DEBUG: Initializing form controllers with transaction ID: ${transaction.id}');
    _amountController = TextEditingController(text: transaction.amount.toString());
    _noteController = TextEditingController(text: transaction.note ?? '');
    _descriptionController = TextEditingController(text: transaction.description ?? '');
    
    // Initialize other providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(add_transaction.transactionTypeProvider.notifier).state = 
          category?.type == 'income' ? add_transaction.TransactionType.income : add_transaction.TransactionType.expense;
      ref.read(add_transaction.selectedDateProvider.notifier).state = transaction.date;
      ref.read(add_transaction.selectedCategoryProvider.notifier).state = transaction.categoryId;
      ref.read(add_transaction.selectedAccountProvider.notifier).state = transaction.accountId;
      ref.read(add_transaction.isSharedExpenseProvider.notifier).state = transaction.isShared;
      if (transaction.isShared) {
        ref.read(add_transaction.selectedGroupProvider.notifier).state = transaction.groupId;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final transactionType = ref.watch(add_transaction.transactionTypeProvider);
    final selectedDate = ref.watch(add_transaction.selectedDateProvider);
    final isSharedExpense = ref.watch(add_transaction.isSharedExpenseProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: _buildAppBar(context, ref),
      body: Stack(
        children: [
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160), // Extra padding for both buttons
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type Display (Read-only)
                  _buildTransactionTypeDisplay(transactionType),
                  
                  AppTheme.verticalSpaceLarge,
                  
                  // Amount Input
                  _buildAmountInput(),
                  
                  AppTheme.verticalSpaceLarge,
                  
                  // Date Selection
                  _buildDateSelector(context, ref, selectedDate),
                  
                  AppTheme.verticalSpaceLarge,
                  
                  // Category Selection
                  const CategorySelector(),
                  
                  AppTheme.verticalSpaceLarge,
                  
                  // Account Selection  
                  const AccountSelector(),
                  
                  AppTheme.verticalSpaceLarge,
                  
                  // Note Input
                  _buildNoteInput(ref),
                  
                  AppTheme.verticalSpaceMedium,
                  
                  // Description Input
                  _buildDescriptionInput(ref),
                  
                  AppTheme.verticalSpaceLarge,
                  
                  // Shared Expense Section (only for expenses)
                  if (transactionType == add_transaction.TransactionType.expense) ...[
                    _buildSharedExpenseToggle(ref, isSharedExpense),
                    
                    if (isSharedExpense) ...[
                      AppTheme.verticalSpaceMedium,
                      const SharedExpenseSection(),
                    ],
                  ],
                  
                  AppTheme.verticalSpaceLarge,
                ],
              ),
            ),
          ),
          
          // Fixed buttons at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildActionButtons(context, ref),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text('Edit Transaction'),
      backgroundColor: AppTheme.primaryBackground,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppTheme.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        TextButton(
          onPressed: () => _resetForm(ref),
          child: const Text(
            'Reset',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTypeDisplay(add_transaction.TransactionType currentType) {
    final isIncome = currentType == add_transaction.TransactionType.income;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
          ),
          AppTheme.horizontalSpaceMedium,
          Text(
            'Transaction Type',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isIncome 
                  ? AppTheme.incomeColor.withValues(alpha: 0.1)
                  : AppTheme.expenseColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
              ),
            ),
            child: Text(
              isIncome ? 'Income' : 'Expense',
              style: TextStyle(
                color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    print('DEBUG: _buildAmountInput called with controller value: ${_amountController.text}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        AppTheme.verticalSpaceSmall,
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: AppTheme.cardBorderRadius,
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 24,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        AppTheme.verticalSpaceSmall,
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppTheme.activeTabColor,
                      surface: AppTheme.cardBackground,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              ref.read(add_transaction.selectedDateProvider.notifier).state = pickedDate;
            }
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
                const Icon(Icons.calendar_today, color: AppTheme.textSecondary),
                AppTheme.horizontalSpaceMedium,
                Text(
                  DateFormat('MMM dd, yyyy').format(selectedDate),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Note',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        AppTheme.verticalSpaceSmall,
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: AppTheme.cardBorderRadius,
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: TextFormField(
            controller: _noteController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Enter a note (optional)',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        AppTheme.verticalSpaceSmall,
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: AppTheme.cardBorderRadius,
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: TextFormField(
            controller: _descriptionController,
            style: const TextStyle(color: AppTheme.textPrimary),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter additional details (optional)',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedExpenseToggle(WidgetRef ref, bool isSharedExpense) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people,
            color: isSharedExpense ? AppTheme.activeTabColor : AppTheme.textSecondary,
          ),
          AppTheme.horizontalSpaceMedium,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shared Expense',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isSharedExpense)
                  const Text(
                    'Split this expense with family/group',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: isSharedExpense,
            onChanged: (value) {
              ref.read(add_transaction.isSharedExpenseProvider.notifier).state = value;
            },
            activeThumbColor: AppTheme.activeTabColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Delete Button
              Expanded(
                child: ElevatedButton(
                  onPressed: ref.watch(deletingTransactionProvider) ? null : () {
                    _showDeleteConfirmation(context, ref);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.expenseColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.buttonBorderRadius,
                    ),
                  ),
                  child: ref.watch(deletingTransactionProvider) 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                          ),
                        )
                      : const Text(
                          'Delete',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              AppTheme.horizontalSpaceMedium,
              
              // Update Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: ref.watch(add_transaction.savingTransactionProvider) ? null : () {
                    _updateTransaction(context, ref);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.activeTabColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.buttonBorderRadius,
                    ),
                  ),
                  child: ref.watch(add_transaction.savingTransactionProvider) 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                          ),
                        )
                      : const Text(
                          'Update Transaction',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Delete Transaction',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to delete this transaction? This action cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTransaction(context, ref);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.expenseColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateTransaction(BuildContext context, WidgetRef ref) async {
    // Set loading state
    ref.read(add_transaction.savingTransactionProvider.notifier).state = true;
    
    // Helper function to clear loading state and show error
    void clearLoadingAndShowError(String message) {
      ref.read(add_transaction.savingTransactionProvider.notifier).state = false;
      _showError(context, message);
    }
    
    try {
      final amount = _amountController.text;
      final selectedDate = ref.read(add_transaction.selectedDateProvider);
      final selectedCategory = ref.read(add_transaction.selectedCategoryProvider);
      final selectedAccount = ref.read(add_transaction.selectedAccountProvider);
      final note = _noteController.text.trim();
      final description = _descriptionController.text.trim();
      final isSharedExpense = ref.read(add_transaction.isSharedExpenseProvider);
      final selectedGroup = ref.read(add_transaction.selectedGroupProvider);
      
      // Basic validation
      if (amount.isEmpty || double.tryParse(amount) == null) {
        clearLoadingAndShowError('Please enter a valid amount');
        return;
      }
      
      final amountValue = double.parse(amount);
      if (amountValue <= 0) {
        clearLoadingAndShowError('Amount must be greater than zero');
        return;
      }
      
      if (selectedCategory == null) {
        clearLoadingAndShowError('Please select a category');
        return;
      }
      
      if (selectedAccount == null) {
        clearLoadingAndShowError('Please select an account');
        return;
      }
      
      if (isSharedExpense && selectedGroup == null) {
        clearLoadingAndShowError('Please select a group for shared expense');
        return;
      }
      
      // Get transaction service
      final transactionService = ref.read(transactionServiceProvider);
      
      // Update transaction
      print('DEBUG: Updating transaction ID ${widget.transactionWithDetails.transaction.id} with amount: $amountValue');
      print('DEBUG: Original amount was: ${widget.transactionWithDetails.transaction.amount}');
      
      final updatedTransaction = await transactionService.updateTransaction(
        id: widget.transactionWithDetails.transaction.id!,
        amount: amountValue,
        date: selectedDate,
        accountId: selectedAccount,
        categoryId: selectedCategory,
        note: note.isNotEmpty ? note : null,
        description: description.isNotEmpty ? description : null,
      );
      
      print('DEBUG: Updated transaction amount: ${updatedTransaction.amount}');
      
      // Refresh providers to update UI immediately
      print('DEBUG: Invalidating providers for UI refresh');
      ref.invalidate(leafAccountsProvider);
      ref.invalidate(monthlyTransactionsProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(dailySummariesProvider);
      
      // Also invalidate account screen providers to refresh balances
      ref.invalidate(accountsTreeProvider);
      ref.invalidate(assetsLiabilitiesProvider);
      
      // Show success message only if the context is still valid
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated successfully!'),
            backgroundColor: AppTheme.activeTabColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Go back only if still mounted
      if (mounted && context.mounted) {
        Navigator.of(context).pop(true); // Pass true to indicate success
      }
      
    } catch (e) {
      _showError(context, 'Failed to update transaction: ${e.toString()}');
    } finally {
      // Clear loading state
      ref.read(add_transaction.savingTransactionProvider.notifier).state = false;
    }
  }

  void _deleteTransaction(BuildContext context, WidgetRef ref) async {
    // Set loading state
    ref.read(deletingTransactionProvider.notifier).state = true;
    
    try {
      // Get transaction service
      final transactionService = ref.read(transactionServiceProvider);
      
      // Delete transaction
      await transactionService.deleteTransaction(widget.transactionWithDetails.transaction.id!);
      
      // Refresh providers to update UI immediately
      ref.invalidate(leafAccountsProvider);
      ref.invalidate(monthlyTransactionsProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(dailySummariesProvider);
      
      // Also invalidate account screen providers to refresh balances
      ref.invalidate(accountsTreeProvider);
      ref.invalidate(assetsLiabilitiesProvider);
      
      // Show success message only if the context is still valid
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully!'),
            backgroundColor: AppTheme.activeTabColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Go back only if still mounted
      if (mounted && context.mounted) {
        Navigator.of(context).pop(true); // Pass true to indicate success
      }
      
    } catch (e) {
      _showError(context, 'Failed to delete transaction: ${e.toString()}');
    } finally {
      // Clear loading state
      ref.read(deletingTransactionProvider.notifier).state = false;
    }
  }
  
  void _resetForm(WidgetRef ref) {
    final transaction = widget.transactionWithDetails.transaction;
    final category = widget.transactionWithDetails.category;
    
    // Reset to original values
    ref.read(add_transaction.transactionTypeProvider.notifier).state = 
        category?.type == 'income' ? add_transaction.TransactionType.income : add_transaction.TransactionType.expense;
    _amountController.text = transaction.amount.toString();
    _noteController.text = transaction.note ?? '';
    _descriptionController.text = transaction.description ?? '';
    ref.read(add_transaction.selectedDateProvider.notifier).state = transaction.date;
    ref.read(add_transaction.selectedCategoryProvider.notifier).state = transaction.categoryId;
    ref.read(add_transaction.selectedAccountProvider.notifier).state = transaction.accountId;
    ref.read(add_transaction.isSharedExpenseProvider.notifier).state = transaction.isShared;
    if (transaction.isShared) {
      ref.read(add_transaction.selectedGroupProvider.notifier).state = transaction.groupId;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.expenseColor,
      ),
    );
  }
}