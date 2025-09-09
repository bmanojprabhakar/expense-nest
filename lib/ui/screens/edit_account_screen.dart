import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../services/account_service.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/account.dart';

// Providers for edit form state
final editAccountNameProvider = StateProvider<String>((ref) => '');
final editInitialBalanceProvider = StateProvider<String>((ref) => '0.00');
final editSavingAccountProvider = StateProvider<bool>((ref) => false);

// Credit card specific fields
final editStatementDayProvider = StateProvider<int?>((ref) => null);
final editGracePeriodDaysProvider = StateProvider<int?>((ref) => null);

// Provider for account service
final editAccountServiceProvider = Provider<AccountService>((ref) {
  final dbHelper = DatabaseHelper();
  return AccountService(dbHelper);
});

class EditAccountScreen extends ConsumerStatefulWidget {
  final Account account;

  const EditAccountScreen({
    super.key,
    required this.account,
  });

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize form with current account data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editAccountNameProvider.notifier).state = widget.account.name;
      ref.read(editInitialBalanceProvider.notifier).state = widget.account.balance.toStringAsFixed(2);
      ref.read(editStatementDayProvider.notifier).state = widget.account.statementDay;
      ref.read(editGracePeriodDaysProvider.notifier).state = widget.account.gracePeriodDays;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(editSavingAccountProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Edit Account'),
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

            // Parent Account (read-only)
            _buildSectionHeader('Parent Account'),
            AppTheme.verticalSpaceSmall,
            _buildParentAccountDisplay(),

            AppTheme.verticalSpaceLarge,

            // Current Balance
            _buildSectionHeader('Current Balance'),
            AppTheme.verticalSpaceSmall,
            _buildBalanceField(ref),

            AppTheme.verticalSpaceLarge,

            // Credit card specific fields (only show if account is credit card type)
            ...(_buildCreditCardFields(context, ref)),

            AppTheme.verticalSpaceLarge,

            // Account Information
            _buildAccountInfo(),

            AppTheme.verticalSpaceLarge,

            // Delete Account Button
            _buildDeleteAccountButton(context, ref),
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
      controller: TextEditingController(text: ref.watch(editAccountNameProvider))
        ..selection = TextSelection.fromPosition(TextPosition(offset: ref.watch(editAccountNameProvider).length)),
      onChanged: (value) => ref.read(editAccountNameProvider.notifier).state = value,
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

  Widget _buildParentAccountDisplay() {
    return FutureBuilder<String>(
      future: _getParentAccountName(),
      builder: (context, snapshot) {
        final parentName = snapshot.data ?? 'Loading...';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: AppTheme.cardBorderRadius,
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_tree,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              AppTheme.horizontalSpaceSmall,
              Expanded(
                child: Text(
                  'Parent: $parentName',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.lock,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _getParentAccountName() async {
    if (widget.account.parentId == null) {
      return 'Root Level';
    }
    
    try {
      final accountService = ref.read(editAccountServiceProvider);
      final parentAccount = await accountService.getAccountById(widget.account.parentId!);
      return parentAccount?.name ?? 'Unknown Parent';
    } catch (e) {
      return 'Unknown Parent';
    }
  }

  Widget _buildBalanceField(WidgetRef ref) {
    return TextField(
      controller: TextEditingController(text: ref.watch(editInitialBalanceProvider))
        ..selection = TextSelection.fromPosition(TextPosition(offset: ref.watch(editInitialBalanceProvider).length)),
      onChanged: (value) => ref.read(editInitialBalanceProvider.notifier).state = value,
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

  List<Widget> _buildCreditCardFields(BuildContext context, WidgetRef ref) {
    // Check if this account's parent is "Credit Cards" 
    // We need to get the parent account to check its name
    return [
      FutureBuilder<Account?>(
        future: _getParentAccount(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          
          final parentAccount = snapshot.data;
          final isCredidCard = parentAccount?.name.toLowerCase() == 'credit cards';
          
          if (!isCredidCard) return const SizedBox.shrink();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildCreditCardFieldsContent(context, ref),
          );
        },
      )
    ];
  }
  
  Future<Account?> _getParentAccount() async {
    if (widget.account.parentId == null) return null;
    final accountService = ref.read(editAccountServiceProvider);
    return await accountService.getAccountById(widget.account.parentId!);
  }
  
  List<Widget> _buildCreditCardFieldsContent(BuildContext context, WidgetRef ref) {
    
    return [
      _buildSectionHeader('Credit Card Details'),
      AppTheme.verticalSpaceSmall,
      _buildDayField(
        ref,
        'Statement Day',
        editStatementDayProvider,
        'Day of month when statement is generated (1-31)',
      ),
      AppTheme.verticalSpaceSmall,
      _buildDayField(
        ref,
        'Grace Period (Days)',
        editGracePeriodDaysProvider,
        'Days from statement to pay without interest (1-60)',
      ),
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

  Widget _buildAccountInfo() {
    String info = 'You can edit the account name and balance. ';
    
    if (widget.account.isCreditCard) {
      info += 'This is a credit card account, so you can also set statement and payment due dates.';
    } else {
      info += 'Parent account and account type cannot be changed.';
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

  Widget _buildDeleteAccountButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDeleteAccount(context, ref),
        icon: const Icon(
          Icons.delete_outline,
          color: AppTheme.expenseColor,
        ),
        label: const Text(
          'Delete Account',
          style: TextStyle(
            color: AppTheme.expenseColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AppTheme.expenseColor,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.cardBorderRadius,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    // First check if account can be deleted
    final accountService = ref.read(editAccountServiceProvider);
    final canDelete = await accountService.canDeleteAccount(widget.account.id!);
    
    if (!canDelete) {
      _showError(context, 'Cannot delete account that has child accounts. Please delete child accounts first.');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.account.name}"? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
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
      ),
    );

    if (confirmed == true) {
      await _deleteAccount(context, ref);
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      final accountService = ref.read(editAccountServiceProvider);
      await accountService.deleteAccount(widget.account.id!);

      if (context.mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account "${widget.account.name}" deleted successfully'),
            backgroundColor: AppTheme.incomeColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString().replaceFirst('ArgumentError: ', ''));
      }
    }
  }

  Future<void> _saveAccount(BuildContext context, WidgetRef ref) async {
    final name = ref.read(editAccountNameProvider);
    final balanceStr = ref.read(editInitialBalanceProvider);
    final statementDay = ref.read(editStatementDayProvider);
    final gracePeriodDays = ref.read(editGracePeriodDaysProvider);

    if (name.trim().isEmpty) {
      _showError(context, 'Please enter an account name');
      return;
    }

    double balance = 0.0;
    try {
      balance = double.parse(balanceStr.isEmpty ? '0' : balanceStr);
    } catch (e) {
      _showError(context, 'Please enter a valid balance');
      return;
    }

    try {
      ref.read(editSavingAccountProvider.notifier).state = true;
      
      final accountService = ref.read(editAccountServiceProvider);
      
      // Update account with all new details including credit card fields
      await accountService.updateAccountComplete(
        id: widget.account.id!,
        name: name.trim(),
        balance: balance,
        statementDay: statementDay,
        gracePeriodDays: gracePeriodDays,
      );

      if (context.mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to update account: ${e.toString()}');
      }
    } finally {
      ref.read(editSavingAccountProvider.notifier).state = false;
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