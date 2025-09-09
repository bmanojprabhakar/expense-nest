import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../services/account_service.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/account.dart';
import '../widgets/hierarchical_account_tree.dart';

// Providers for form state
final accountNameProvider = StateProvider<String>((ref) => '');
final parentAccountProvider = StateProvider<Account?>((ref) => null);
final initialBalanceProvider = StateProvider<String>((ref) => '0.00');
final savingAccountProvider = StateProvider<bool>((ref) => false);

// Credit card specific fields
final statementDayProvider = StateProvider<int?>((ref) => null);
final gracePeriodDaysProvider = StateProvider<int?>((ref) => null);

// Provider for existing accounts tree
final existingAccountsTreeProvider = FutureProvider<List<AccountNode>>((ref) async {
  final accountService = ref.read(accountServiceProvider);
  return accountService.buildAccountTree();
});

// Provider for account service
final accountServiceProvider = Provider<AccountService>((ref) {
  final dbHelper = DatabaseHelper();
  return AccountService(dbHelper);
});

class AddAccountScreen extends ConsumerWidget {
  const AddAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(savingAccountProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Add Account'),
        backgroundColor: AppTheme.primaryBackground,
        actions: [
          TextButton(
            onPressed: isSaving ? null : () => _saveAccount(context, ref),
            child: Text(
              'Save',
              style: TextStyle(
                color: isSaving ? AppTheme.textSecondary : AppTheme.activeTabColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppTheme.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Name
            _buildSectionHeader('Account Name'),
            AppTheme.verticalSpaceSmall,
            _buildAccountNameField(ref),

            AppTheme.verticalSpaceLarge,

            // Parent Account (Mandatory)
            _buildSectionHeader('Parent Account *'),
            AppTheme.verticalSpaceSmall,
            _buildParentAccountSelector(context, ref),

            AppTheme.verticalSpaceLarge,

            // Credit card specific fields (only show if parent is credit card)
            ...(_buildCreditCardFields(context, ref)),

            AppTheme.verticalSpaceLarge,

            // Initial Balance
            _buildSectionHeader('Initial Balance'),
            AppTheme.verticalSpaceSmall,
            _buildInitialBalanceField(ref),

            AppTheme.verticalSpaceLarge,

            // Account Information
            _buildAccountInfo(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAccountNameField(WidgetRef ref) {
    return TextField(
      onChanged: (value) => ref.read(accountNameProvider.notifier).state = value,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
      ),
      decoration: const InputDecoration(
        hintText: 'Enter account name',
        filled: true,
        fillColor: AppTheme.cardBackground,
      ),
    );
  }

  List<Widget> _buildCreditCardFields(BuildContext context, WidgetRef ref) {
    final selectedParent = ref.watch(parentAccountProvider);
    
    // Show credit card fields only if parent is "Credit Cards"
    final showCreditCardFields = selectedParent != null && 
                                selectedParent.name.toLowerCase() == 'credit cards';
    
    if (!showCreditCardFields) {
      return [];
    }
    
    return [
      _buildSectionHeader('Credit Card Details'),
      AppTheme.verticalSpaceSmall,
      _buildDayField(
        ref,
        'Statement Day',
        statementDayProvider,
        'Bill cycle end date (1-31)',
      ),
      AppTheme.verticalSpaceSmall,
      _buildGracePeriodField(ref),
    ];
  }
  
  Widget _buildDayField(
    WidgetRef ref,
    String label,
    StateProvider<int?> provider,
    String hint,
  ) {
    final selectedDay = ref.watch(provider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(
            text: selectedDay?.toString() ?? '',
          )..selection = TextSelection.fromPosition(
              TextPosition(offset: selectedDay?.toString().length ?? 0)
            ),
          onChanged: (value) {
            if (value.isEmpty) {
              ref.read(provider.notifier).state = null;
              return;
            }
            
            final intValue = int.tryParse(value);
            if (intValue != null && intValue >= 1 && intValue <= 31) {
              ref.read(provider.notifier).state = intValue;
            }
          },
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
            _DayRangeInputFormatter(),
          ],
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: AppTheme.cardBorderRadius,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorText: _getDayFieldError(selectedDay, value: selectedDay?.toString() ?? ''),
          ),
        ),
      ],
    );
  }

  String? _getDayFieldError(int? day, {String value = ''}) {
    if (value.isNotEmpty && day == null) {
      return 'Enter a valid day (1-31)';
    }
    if (day != null && (day < 1 || day > 31)) {
      return 'Day must be between 1 and 31';
    }
    return null;
  }

  Widget _buildGracePeriodField(WidgetRef ref) {
    final gracePeriodDays = ref.watch(gracePeriodDaysProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grace Period (Days)',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(
            text: gracePeriodDays?.toString() ?? '',
          )..selection = TextSelection.fromPosition(
              TextPosition(offset: gracePeriodDays?.toString().length ?? 0)
            ),
          onChanged: (value) {
            if (value.isEmpty) {
              ref.read(gracePeriodDaysProvider.notifier).state = null;
              return;
            }
            
            final intValue = int.tryParse(value);
            if (intValue != null && intValue >= 1 && intValue <= 60) {
              ref.read(gracePeriodDaysProvider.notifier).state = intValue;
            }
          },
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
            _GracePeriodInputFormatter(),
          ],
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Days from statement to pay without interest (1-60)',
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: AppTheme.cardBorderRadius,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorText: _getGracePeriodError(gracePeriodDays, value: gracePeriodDays?.toString() ?? ''),
          ),
        ),
      ],
    );
  }

  String? _getGracePeriodError(int? days, {String value = ''}) {
    if (value.isNotEmpty && days == null) {
      return 'Enter a valid grace period (1-60 days)';
    }
    if (days != null && (days < 1 || days > 60)) {
      return 'Grace period must be between 1 and 60 days';
    }
    return null;
  }

  Widget _buildInitialBalanceField(WidgetRef ref) {
    return TextField(
      onChanged: (value) => ref.read(initialBalanceProvider.notifier).state = value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
      ),
      decoration: const InputDecoration(
        hintText: '0.00',
        prefixText: '₹ ',
        prefixStyle: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
        ),
        filled: true,
        fillColor: AppTheme.cardBackground,
      ),
    );
  }

  Widget _buildParentAccountSelector(BuildContext context, WidgetRef ref) {
    final selectedParent = ref.watch(parentAccountProvider);
    final accountsTreeAsync = ref.watch(existingAccountsTreeProvider);

    return accountsTreeAsync.when(
      data: (accountTree) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: AppTheme.cardBorderRadius,
          border: Border.all(
            color: selectedParent == null ? AppTheme.expenseColor : AppTheme.dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Selected Parent Display
            ListTile(
              leading: Icon(
                selectedParent != null ? Icons.check_circle : Icons.account_tree,
                color: selectedParent != null ? AppTheme.activeTabColor : AppTheme.textSecondary,
              ),
              title: Text(
                selectedParent?.name ?? 'Select a parent account',
                style: TextStyle(
                  color: selectedParent != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              subtitle: selectedParent != null ? const Text(
                'Tap to change selection',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ) : const Text(
                'Required - Choose where to create this account',
                style: TextStyle(
                  color: AppTheme.expenseColor,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.expand_more),
              onTap: () => _showParentAccountSelector(context, ref, accountTree),
            ),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: AppTheme.cardBorderRadius,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: AppTheme.cardBorderRadius,
        ),
        child: Text(
          'Error loading accounts: $error',
          style: const TextStyle(color: AppTheme.expenseColor),
        ),
      ),
    );
  }

  void _showParentAccountSelector(BuildContext context, WidgetRef ref, List<AccountNode> accountTree) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Parent Account',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.5),
                  borderRadius: AppTheme.cardBorderRadius,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select any account from the tree below as the parent for your new account.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Account Tree
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: accountTree.map((node) => _buildSelectableAccountNode(context, ref, node, 0)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableAccountNode(BuildContext context, WidgetRef ref, AccountNode node, int depth) {
    final indentation = depth * 24.0;
    final account = node.account;
    final hasChildren = node.children.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: indentation, bottom: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(parentAccountProvider.notifier).state = account;
                Navigator.of(context).pop();
              },
              borderRadius: AppTheme.cardBorderRadius,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: hasChildren ? 0.8 : 0.5),
                  borderRadius: AppTheme.cardBorderRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      hasChildren ? Icons.folder : Icons.account_circle,
                      color: hasChildren ? AppTheme.activeTabColor : AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        account.name,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: hasChildren ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Children
        ...node.children.map((child) => _buildSelectableAccountNode(context, ref, child, depth + 1)),
      ],
    );
  }

  Widget _buildAccountInfo(WidgetRef ref) {
    final selectedParent = ref.watch(parentAccountProvider);
    
    String info;
    if (selectedParent == null) {
      info = 'Select a parent account to create a new leaf account under it.';
    } else {
      final parentName = selectedParent.name;
      info = 'This account will be created under "$parentName" and can hold transactions.';
      
      // Check if parent is "Credit Cards"
      if (selectedParent.name.toLowerCase() == 'credit cards') {
        info += ' Credit card account - you can set statement day and grace period.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.5),
        borderRadius: AppTheme.cardBorderRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          AppTheme.horizontalSpaceSmall,
          Expanded(
            child: Text(
              info,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'credit_card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      case 'cash':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.account_balance;
    }
  }

  Color _getAccountIconColor(String type) {
    switch (type) {
      case 'credit_card':
        return Colors.blue;
      case 'bank':
        return Colors.green;
      case 'cash':
        return Colors.orange;
      case 'savings':
        return Colors.purple;
      default:
        return AppTheme.textSecondary;
    }
  }

  Future<void> _saveAccount(BuildContext context, WidgetRef ref) async {
    final name = ref.read(accountNameProvider);
    final parentAccount = ref.read(parentAccountProvider);
    final balanceStr = ref.read(initialBalanceProvider);
    final statementDay = ref.read(statementDayProvider);
    final gracePeriodDays = ref.read(gracePeriodDaysProvider);

    if (name.trim().isEmpty) {
      _showError(context, 'Please enter an account name');
      return;
    }

    if (parentAccount == null) {
      _showError(context, 'Please select a parent account');
      return;
    }

    double balance = 0.0;
    try {
      balance = double.parse(balanceStr.isEmpty ? '0' : balanceStr);
    } catch (e) {
      _showError(context, 'Please enter a valid balance');
      return;
    }

    // Determine account type from parent name only - simpler and more reliable
    String accountType = 'account'; // default
    
    if (parentAccount.name.toLowerCase() == 'credit cards') {
      accountType = 'credit_card';
    } else if (parentAccount.name.toLowerCase().contains('bank')) {
      accountType = 'bank';
    } else if (parentAccount.name.toLowerCase().contains('cash')) {
      accountType = 'cash';
    } else if (parentAccount.name.toLowerCase().contains('savings')) {
      accountType = 'savings';
    }

    try {
      ref.read(savingAccountProvider.notifier).state = true;
      
      final accountService = ref.read(accountServiceProvider);
      await accountService.createAccount(
        name: name,
        parentId: parentAccount.id!,
        accountType: accountType,
        initialBalance: balance,
        statementDay: statementDay,
        gracePeriodDays: gracePeriodDays,
      );

      if (context.mounted) {
        // Reset form
        ref.read(accountNameProvider.notifier).state = '';
        ref.read(parentAccountProvider.notifier).state = null;
        ref.read(initialBalanceProvider.notifier).state = '0.00';
        ref.read(statementDayProvider.notifier).state = null;
        ref.read(gracePeriodDaysProvider.notifier).state = null;
        
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to create account: ${e.toString()}');
      }
    } finally {
      ref.read(savingAccountProvider.notifier).state = false;
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

// Custom input formatter to ensure day values are between 1-31
class _DayRangeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }
    
    final intValue = int.tryParse(text);
    
    // If it's not a valid integer or exceeds 31, reject the change
    if (intValue == null || intValue > 31) {
      return oldValue;
    }
    
    // Allow single digits and valid two-digit numbers (1-31)
    return newValue;
  }
}

// Custom input formatter to ensure grace period values are between 1-60
class _GracePeriodInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }
    
    final intValue = int.tryParse(text);
    
    // If it's not a valid integer or exceeds 60, reject the change
    if (intValue == null || intValue > 60) {
      return oldValue;
    }
    
    // Allow single digits and valid two-digit numbers (1-60)
    return newValue;
  }
}