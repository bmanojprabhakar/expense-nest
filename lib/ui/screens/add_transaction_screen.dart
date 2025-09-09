import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../widgets/category_selector.dart';
import '../widgets/account_selector.dart';
import '../widgets/shared_expense_section.dart';
import '../../data/models/transaction.dart' as app_transaction;
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';

// Providers for form state
final transactionTypeProvider = StateProvider<TransactionType>((ref) => TransactionType.expense);
final selectedAmountProvider = StateProvider<String>((ref) => '');
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final selectedCategoryProvider = StateProvider<int?>((ref) => null);
final selectedAccountProvider = StateProvider<int?>((ref) => null);
final transactionNoteProvider = StateProvider<String>((ref) => '');
final transactionDescriptionProvider = StateProvider<String>((ref) => '');
final isSharedExpenseProvider = StateProvider<bool>((ref) => false);
final selectedGroupProvider = StateProvider<int?>((ref) => null);

// Provider for saving transaction state
final savingTransactionProvider = StateProvider<bool>((ref) => false);

enum TransactionType { income, expense }

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late final TextEditingController _noteController;
  late final TextEditingController _descriptionController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with empty values for fresh form
    _noteController = TextEditingController();
    _descriptionController = TextEditingController();
    
    // Initialize form with fresh state when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetForm(ref);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionType = ref.watch(transactionTypeProvider);
    final amount = ref.watch(selectedAmountProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final isSharedExpense = ref.watch(isSharedExpenseProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: _buildAppBar(context, ref),
      body: Stack(
        children: [
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Extra bottom padding for save button
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type Toggle (Income/Expense)
                  _buildTransactionTypeToggle(ref, transactionType),
                  
                  AppTheme.verticalSpaceLarge,
                  
                  // Amount Input
                  _buildAmountInput(ref, amount),
                  
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
                  if (transactionType == TransactionType.expense) ...[
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
          
          // Fixed Save Button at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSaveButton(context, ref),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text('Add Transaction'),
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

  Widget _buildTransactionTypeToggle(WidgetRef ref, TransactionType currentType) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => ref.read(transactionTypeProvider.notifier).state = TransactionType.expense,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: currentType == TransactionType.expense 
                      ? AppTheme.expenseColor
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_circle_outline,
                      color: currentType == TransactionType.expense 
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                    AppTheme.horizontalSpaceSmall,
                    Text(
                      'Expense',
                      style: TextStyle(
                        color: currentType == TransactionType.expense 
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontWeight: currentType == TransactionType.expense 
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => ref.read(transactionTypeProvider.notifier).state = TransactionType.income,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: currentType == TransactionType.income 
                      ? AppTheme.incomeColor
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: currentType == TransactionType.income 
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                    AppTheme.horizontalSpaceSmall,
                    Text(
                      'Income',
                      style: TextStyle(
                        color: currentType == TransactionType.income 
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontWeight: currentType == TransactionType.income 
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(WidgetRef ref, String amount) {
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
          child: TextField(
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
            onChanged: (value) {
              ref.read(selectedAmountProvider.notifier).state = value;
            },
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
              ref.read(selectedDateProvider.notifier).state = pickedDate;
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
          child: TextField(
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
          child: TextField(
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
                Text(
                  'Shared Expense',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isSharedExpense)
                  Text(
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
              ref.read(isSharedExpenseProvider.notifier).state = value;
            },
            activeThumbColor: AppTheme.activeTabColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
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
              onPressed: ref.watch(savingTransactionProvider) ? null : () {
                _saveTransaction(context, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.activeTabColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonBorderRadius,
                ),
              ),
              child: ref.watch(savingTransactionProvider) 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                      ),
                    )
                  : const Text(
                      'Save Transaction',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveTransaction(BuildContext context, WidgetRef ref) async {
    // Set loading state
    ref.read(savingTransactionProvider.notifier).state = true;
    
    try {
      final amount = ref.read(selectedAmountProvider);
      final transactionType = ref.read(transactionTypeProvider);
      final selectedDate = ref.read(selectedDateProvider);
      final selectedCategory = ref.read(selectedCategoryProvider);
      final selectedAccount = ref.read(selectedAccountProvider);
      final note = _noteController.text.trim();
      final description = _descriptionController.text.trim();
      final isSharedExpense = ref.read(isSharedExpenseProvider);
      final selectedGroup = ref.read(selectedGroupProvider);
      
      // Basic validation
      if (amount.isEmpty || double.tryParse(amount) == null) {
        _showError(context, 'Please enter a valid amount');
        return;
      }
      
      final amountValue = double.parse(amount);
      if (amountValue <= 0) {
        _showError(context, 'Amount must be greater than zero');
        return;
      }
      
      if (selectedCategory == null) {
        _showError(context, 'Please select a category');
        return;
      }
      
      if (selectedAccount == null) {
        _showError(context, 'Please select an account');
        return;
      }
      
      if (isSharedExpense && selectedGroup == null) {
        _showError(context, 'Please select a group for shared expense');
        return;
      }
      
      // Get transaction service
      final transactionService = ref.read(transactionServiceProvider);
      
      app_transaction.Transaction savedTransaction;
      
      // The service expects positive amounts and handles the sign internally
      // So we always pass positive amounts
      final adjustedAmount = amountValue.abs();
      
      // Determine if this is an income transaction
      final isIncomeTransaction = transactionType == TransactionType.income;

      if (isSharedExpense && selectedGroup != null) {
        // Create shared transaction with equal split
        savedTransaction = await transactionService.createSharedTransactionEqualSplit(
          amount: adjustedAmount,
          date: selectedDate,
          accountId: selectedAccount,
          categoryId: selectedCategory,
          groupId: selectedGroup,
          note: note.isNotEmpty ? note : null,
          description: description.isNotEmpty ? description : null,
          isIncome: isIncomeTransaction,
        );
      } else {
        // Create personal transaction
        savedTransaction = await transactionService.createPersonalTransaction(
          amount: adjustedAmount,
          date: selectedDate,
          accountId: selectedAccount,
          categoryId: selectedCategory,
          note: note.isNotEmpty ? note : null,
          description: description.isNotEmpty ? description : null,
          isIncome: isIncomeTransaction,
        );
      }
      
      // Refresh providers to update UI immediately
      ref.invalidate(leafAccountsProvider);
      ref.invalidate(monthlyTransactionsProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(dailySummariesProvider);
      
      // Also invalidate account screen providers to refresh balances
      ref.invalidate(accountsTreeProvider);
      ref.invalidate(assetsLiabilitiesProvider);
      
      // Show success message
      final transactionTypeText = transactionType.name.toUpperCase();
      final amountText = AppTheme.formatCurrency(amountValue, showSign: true);
      final shareText = isSharedExpense ? ' (shared)' : '';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$transactionTypeText: $amountText saved$shareText!'),
          backgroundColor: AppTheme.activeTabColor,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Clear form and go back
      _resetForm(ref);
      Navigator.of(context).pop(true); // Pass true to indicate success
      
    } catch (e) {
      _showError(context, 'Failed to save transaction: ${e.toString()}');
    } finally {
      // Clear loading state
      ref.read(savingTransactionProvider.notifier).state = false;
    }
  }
  
  void _resetForm(WidgetRef ref) {
    ref.read(transactionTypeProvider.notifier).state = TransactionType.expense;
    ref.read(selectedAmountProvider.notifier).state = '';
    ref.read(selectedDateProvider.notifier).state = DateTime.now();
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.read(selectedAccountProvider.notifier).state = null;
    _noteController.clear();
    _descriptionController.clear();
    ref.read(transactionNoteProvider.notifier).state = '';
    ref.read(transactionDescriptionProvider.notifier).state = '';
    ref.read(isSharedExpenseProvider.notifier).state = false;
    ref.read(selectedGroupProvider.notifier).state = null;
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