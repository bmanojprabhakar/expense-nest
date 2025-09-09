import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/account_service.dart';
import '../data/database/database_helper.dart';
import '../data/models/account.dart';

// Export the types needed by consumers
export '../data/models/account.dart';

// Provider for current selected month in accounts screen
final accountsSelectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider for current selected tab in accounts screen
final accountsSelectedTabProvider = StateProvider<String>((ref) => 'All Accounts');

// Provider for credit card summary (billed/unbilled transactions)
final creditCardSummaryProvider = FutureProvider<CreditCardSummary>((ref) async {
  final selectedMonth = ref.watch(accountsSelectedMonthProvider);
  final creditCards = await ref.watch(creditCardsProvider.future);
  
  if (creditCards.isEmpty) {
    return CreditCardSummary(
      billedAmount: 0.0,
      unbilledAmount: 0.0,
      totalAmount: 0.0,
    );
  }
  
  double totalBilled = 0.0;
  double totalUnbilled = 0.0;
  
  // Get database helper for transaction queries
  final dbHelper = DatabaseHelper();
  
  for (final card in creditCards) {
    if (card.statementDay == null) continue;
    
    final summary = await _calculateCardBilledUnbilled(card, selectedMonth, dbHelper);
    totalBilled += summary.billedAmount;
    totalUnbilled += summary.unbilledAmount;
  }
  
  return CreditCardSummary(
    billedAmount: totalBilled,
    unbilledAmount: totalUnbilled,
    totalAmount: totalBilled + totalUnbilled,
  );
});

// Helper to calculate billed/unbilled for a single card
Future<CreditCardSummary> _calculateCardBilledUnbilled(
  Account card, 
  DateTime selectedMonth,
  DatabaseHelper dbHelper,
) async {
  final now = DateTime.now();
  final currentDay = now.day;
  final statementDay = card.statementDay!;
  
  // Determine the current billing cycle
  DateTime currentStatementDate;
  DateTime previousStatementDate;
  
  if (currentDay >= statementDay) {
    // We're past statement day for this month
    currentStatementDate = DateTime(now.year, now.month, statementDay);
    previousStatementDate = DateTime(now.year, now.month - 1, statementDay);
  } else {
    // We haven't reached statement day yet
    currentStatementDate = DateTime(now.year, now.month - 1, statementDay);
    previousStatementDate = DateTime(now.year, now.month - 2, statementDay);
  }
  
  // Get transactions for the selected month
  final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1).subtract(const Duration(days: 1));
  
  final allTransactions = await dbHelper.getTransactionsForDateRange(startOfMonth, endOfMonth);
  final cardTransactions = allTransactions.where((t) => t.accountId == card.id).toList();
  
  double billedAmount = 0.0;
  double unbilledAmount = 0.0;
  
  for (final transaction in cardTransactions) {
    if (transaction.date.isAfter(currentStatementDate) || transaction.date.isAtSameMomentAs(currentStatementDate)) {
      // Transaction after current statement - unbilled
      unbilledAmount += transaction.amount;
    } else if (transaction.date.isAfter(previousStatementDate)) {
      // Transaction between previous and current statement - billed
      billedAmount += transaction.amount;
    }
  }
  
  return CreditCardSummary(
    billedAmount: billedAmount,
    unbilledAmount: unbilledAmount,
    totalAmount: billedAmount + unbilledAmount,
  );
}

// Data class for credit card summary
class CreditCardSummary {
  final double billedAmount;
  final double unbilledAmount;
  final double totalAmount;
  
  CreditCardSummary({
    required this.billedAmount,
    required this.unbilledAmount,
    required this.totalAmount,
  });
}

// Provider for monthly account balances (only used for Credit Cards tab with month navigation)
final monthlyAccountsTreeProvider = FutureProvider<List<AccountNode>>((ref) async {
  final selectedMonth = ref.watch(accountsSelectedMonthProvider);
  final accountService = ref.read(accountServiceProvider);
  
  // For Credit Cards, we still use current account structure but filter transactions by month
  // This is mainly used for the credit card statement view
  final accountTree = await accountService.buildAccountTree();
  
  return accountTree;
});


// Centralized provider for account service
final accountServiceProvider = Provider<AccountService>((ref) {
  final dbHelper = DatabaseHelper();
  return AccountService(dbHelper);
});

// Provider for leaf accounts (only accounts that can have transactions)
final leafAccountsProvider = FutureProvider<List<Account>>((ref) async {
  final accountService = ref.read(accountServiceProvider);
  return accountService.getLeafAccounts();
});

// Provider for account path mapping (to show parent names)
final accountPathsProvider = FutureProvider<Map<int, List<String>>>((ref) async {
  final accountService = ref.read(accountServiceProvider);
  final leafAccounts = await accountService.getLeafAccounts();
  
  final pathsMap = <int, List<String>>{};
  for (final account in leafAccounts) {
    if (account.id != null) {
      pathsMap[account.id!] = await accountService.getAccountPath(account.id!);
    }
  }
  return pathsMap;
});

// Provider for accounts tree
final accountsTreeProvider = FutureProvider<List<AccountNode>>((ref) async {
  final accountService = ref.read(accountServiceProvider);
  return accountService.buildAccountTree();
});

// Provider for account summary
final accountSummaryProvider = FutureProvider<AccountSummary>((ref) async {
  final accountService = ref.read(accountServiceProvider);
  return accountService.getAccountSummary();
});

// Data class for asset/liability breakdown
class AssetLiabilityBreakdown {
  final double assets;
  final double liabilities;
  final double netWorth;
  
  const AssetLiabilityBreakdown({
    required this.assets,
    required this.liabilities,
    required this.netWorth,
  });
}

// Provider for proper assets/liabilities calculation
final assetsLiabilitiesProvider = FutureProvider<AssetLiabilityBreakdown>((ref) async {
  final accountService = ref.read(accountServiceProvider);
  final leafAccounts = await accountService.getLeafAccounts();
  
  double assets = 0.0;
  double liabilities = 0.0;
  
  for (final account in leafAccounts) {
    if (account.balance >= 0) {
      assets += account.balance;
    } else {
      liabilities += account.balance.abs();
    }
  }
  
  return AssetLiabilityBreakdown(
    assets: assets,
    liabilities: liabilities,
    netWorth: assets - liabilities,
  );
});

// Provider for credit card accounts only
final creditCardsProvider = FutureProvider<List<Account>>((ref) async {
  final accountService = ref.read(accountServiceProvider);
  final leafAccounts = await accountService.getLeafAccounts();
  final allAccounts = await accountService.getAllAccounts();
  
  // Create a map of account ID to account for parent lookup
  final accountMap = <int, Account>{};
  for (final account in allAccounts) {
    if (account.id != null) {
      accountMap[account.id!] = account;
    }
  }
  
  return leafAccounts.where((account) {
    // Get parent account name if it exists
    String? parentName;
    if (account.parentId != null && accountMap.containsKey(account.parentId)) {
      parentName = accountMap[account.parentId!]!.name;
    }
    
    return account.isCreditCardWithParent(parentName);
  }).toList();
});