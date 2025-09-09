import '../data/database/database_helper.dart';
import '../data/models/transaction.dart';
import '../data/models/split.dart';
import '../data/models/account.dart';
import '../data/models/category.dart';
import '../data/models/user.dart';
import '../data/models/group.dart';
import 'account_service.dart';

class TransactionService {
  final DatabaseHelper _databaseHelper;
  final AccountService _accountService;

  TransactionService(this._databaseHelper, this._accountService);

  // Create a personal (non-shared) transaction
  Future<Transaction> createPersonalTransaction({
    required double amount,
    required DateTime date,
    required int accountId,
    required int categoryId,
    String? note,
    String? description,
    bool? isIncome,
  }) async {
    await _validateTransactionInputs(amount, accountId, categoryId);

    final transaction = Transaction(
      amount: amount.abs(), // Ensure positive amount
      date: date,
      accountId: accountId,
      categoryId: categoryId,
      note: note?.trim(),
      description: description?.trim(),
      isShared: false,
      createdAt: DateTime.now(),
    );

    final transactionId = await _databaseHelper.insertTransaction(transaction);
    final createdTransaction = transaction.copyWith(id: transactionId);

    // Update account balance
    await _updateAccountBalanceForTransaction(createdTransaction, isIncome);

    return createdTransaction;
  }

  // Create a shared transaction with group-based splitting
  Future<Transaction> createSharedTransaction({
    required double amount,
    required DateTime date,
    required int accountId,
    required int categoryId,
    required int groupId,
    required Map<int, double> userShares, // userId -> share amount
    String? note,
    String? description,
    bool? isIncome,
  }) async {
    await _validateTransactionInputs(amount, accountId, categoryId);
    await _validateSharedTransactionInputs(groupId, userShares, amount);

    final transaction = Transaction(
      amount: amount.abs(),
      date: date,
      accountId: accountId,
      categoryId: categoryId,
      note: note?.trim(),
      description: description?.trim(),
      isShared: true,
      groupId: groupId,
      createdAt: DateTime.now(),
    );

    // Create splits
    final splits = Split.createCustomSplits(
      transactionId: 0, // Will be set in database helper
      userShares: userShares,
      totalAmount: amount.abs(),
    );

    // Insert transaction with splits atomically
    final transactionId = await _databaseHelper.insertTransactionWithSplits(
      transaction,
      splits,
    );

    final createdTransaction = transaction.copyWith(id: transactionId);

    // Update account balance
    await _updateAccountBalanceForTransaction(createdTransaction, isIncome);

    return createdTransaction;
  }

  // Create shared transaction with equal splits
  Future<Transaction> createSharedTransactionEqualSplit({
    required double amount,
    required DateTime date,
    required int accountId,
    required int categoryId,
    required int groupId,
    String? note,
    String? description,
    bool? isIncome,
  }) async {
    // Get group members
    final groupMembers = await _databaseHelper.getGroupMemberUsers(groupId);
    if (groupMembers.isEmpty) {
      throw ArgumentError('Group has no active members');
    }

    final userIds = groupMembers.map((user) => user.id!).toList();
    final shareAmount = amount.abs() / userIds.length;
    final userShares = {for (int userId in userIds) userId: shareAmount};

    return await createSharedTransaction(
      amount: amount,
      date: date,
      accountId: accountId,
      categoryId: categoryId,
      groupId: groupId,
      userShares: userShares,
      note: note,
      description: description,
      isIncome: isIncome,
    );
  }

  // Create shared transaction with percentage splits
  Future<Transaction> createSharedTransactionPercentageSplit({
    required double amount,
    required DateTime date,
    required int accountId,
    required int categoryId,
    required int groupId,
    required Map<int, double> userPercentages, // userId -> percentage
    String? note,
    String? description,
  }) async {
    await _validateTransactionInputs(amount, accountId, categoryId);
    await _validatePercentageSplits(groupId, userPercentages);

    final transaction = Transaction(
      amount: amount.abs(),
      date: date,
      accountId: accountId,
      categoryId: categoryId,
      note: note?.trim(),
      description: description?.trim(),
      isShared: true,
      groupId: groupId,
      createdAt: DateTime.now(),
    );

    // Create splits
    final splits = Split.createPercentageSplits(
      transactionId: 0, // Will be set in database helper
      userPercentages: userPercentages,
      totalAmount: amount.abs(),
    );

    final transactionId = await _databaseHelper.insertTransactionWithSplits(
      transaction,
      splits,
    );

    final createdTransaction = transaction.copyWith(id: transactionId);
    await _updateAccountBalanceForTransaction(createdTransaction);

    return createdTransaction;
  }

  // Get transactions for a specific month
  Future<List<TransactionWithDetails>> getTransactionsForMonth(int year, int month) async {
    final transactions = await _databaseHelper.getTransactionsForMonth(year, month);
    return await _enrichTransactionsWithDetails(transactions);
  }

  // Get transactions for a date range
  Future<List<TransactionWithDetails>> getTransactionsForDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final transactions = await _databaseHelper.getTransactionsForDateRange(startDate, endDate);
    return await _enrichTransactionsWithDetails(transactions);
  }

  // Get transactions for a specific account within a date range
  Future<List<TransactionWithDetails>> getTransactionsByDateRange({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await _databaseHelper.getTransactionsForDateRange(startDate, endDate);
    final accountTransactions = transactions.where((t) => t.accountId == accountId).toList();
    return await _enrichTransactionsWithDetails(accountTransactions);
  }

  // Get transactions for a whole year
  Future<List<TransactionWithDetails>> getTransactionsForYear(int year) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);
    return await getTransactionsForDateRange(startDate, endDate);
  }

  // Get transaction by ID with details
  Future<TransactionWithDetails?> getTransactionById(int id) async {
    final transaction = await _databaseHelper.getTransaction(id);
    if (transaction == null) return null;

    final enriched = await _enrichTransactionsWithDetails([transaction]);
    return enriched.isNotEmpty ? enriched.first : null;
  }

  // Update transaction
  Future<Transaction> updateTransaction({
    required int id,
    double? amount,
    DateTime? date,
    int? accountId,
    int? categoryId,
    String? note,
    String? description,
    Map<int, double>? newUserShares, // For shared transactions
  }) async {
    final existingTransaction = await _databaseHelper.getTransaction(id);
    if (existingTransaction == null) {
      throw ArgumentError('Transaction with ID $id not found');
    }

    // Validate inputs if provided
    if (amount != null || accountId != null || categoryId != null) {
      await _validateTransactionInputs(
        amount ?? existingTransaction.amount,
        accountId ?? existingTransaction.accountId,
        categoryId ?? existingTransaction.categoryId,
      );
    }

    final updatedTransaction = existingTransaction.copyWith(
      amount: amount?.abs() ?? existingTransaction.amount,
      date: date ?? existingTransaction.date,
      accountId: accountId ?? existingTransaction.accountId,
      categoryId: categoryId ?? existingTransaction.categoryId,
      note: note?.trim() ?? existingTransaction.note,
      description: description?.trim() ?? existingTransaction.description,
      updatedAt: DateTime.now(),
    );

    // Revert the old account balance change
    await _revertAccountBalanceForTransaction(existingTransaction);

    // Handle splits for shared transactions
    if (existingTransaction.isShared && newUserShares != null) {
      await _validateSharedTransactionInputs(
        existingTransaction.groupId!,
        newUserShares,
        updatedTransaction.amount,
      );

      final newSplits = Split.createCustomSplits(
        transactionId: id,
        userShares: newUserShares,
        totalAmount: updatedTransaction.amount,
      );

      await _databaseHelper.updateTransactionWithSplits(updatedTransaction, newSplits);
    } else {
      await _databaseHelper.updateTransaction(updatedTransaction);
    }

    // Apply the new account balance change
    await _updateAccountBalanceForTransaction(updatedTransaction);

    return updatedTransaction;
  }

  // Delete transaction
  Future<void> deleteTransaction(int id) async {
    final transaction = await _databaseHelper.getTransaction(id);
    if (transaction == null) {
      throw ArgumentError('Transaction with ID $id not found');
    }

    // Revert account balance
    await _revertAccountBalanceForTransaction(transaction);

    // Delete transaction (this will cascade to splits due to foreign key constraint)
    await _databaseHelper.deleteTransaction(id);
  }

  // Get shared expense summary for a group
  Future<GroupExpenseSummary> getGroupExpenseSummary(
    int groupId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final transactions = await _databaseHelper.getTransactionsForDateRange(startDate, endDate);
    final groupTransactions = transactions.where((t) => t.groupId == groupId).toList();

    if (groupTransactions.isEmpty) {
      return GroupExpenseSummary(
        groupId: groupId,
        totalAmount: 0.0,
        transactionCount: 0,
        userSummaries: {},
      );
    }

    final userSummaries = <int, UserExpenseSummary>{};
    double totalAmount = 0.0;

    for (final transaction in groupTransactions) {
      totalAmount += transaction.amount;
      final splits = await _databaseHelper.getSplitsForTransaction(transaction.id!);
      
      for (final split in splits) {
        final userSummary = userSummaries[split.userId] ?? UserExpenseSummary(
          userId: split.userId,
          totalShare: 0.0,
          transactionCount: 0,
        );

        userSummaries[split.userId] = UserExpenseSummary(
          userId: split.userId,
          totalShare: userSummary.totalShare + split.shareAmount,
          transactionCount: userSummary.transactionCount + 1,
        );
      }
    }

    return GroupExpenseSummary(
      groupId: groupId,
      totalAmount: totalAmount,
      transactionCount: groupTransactions.length,
      userSummaries: userSummaries,
    );
  }

  // Get user's expense summary across all groups
  Future<UserTotalExpenseSummary> getUserExpenseSummary(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final transactions = await _databaseHelper.getTransactionsForDateRange(startDate, endDate);
    
    double personalExpenses = 0.0;
    double sharedExpenses = 0.0;
    int personalTransactionCount = 0;
    int sharedTransactionCount = 0;

    for (final transaction in transactions) {
      if (transaction.isShared) {
        final splits = await _databaseHelper.getSplitsForTransaction(transaction.id!);
        final userSplit = splits.where((s) => s.userId == userId).firstOrNull;
        
        if (userSplit != null) {
          sharedExpenses += userSplit.shareAmount;
          sharedTransactionCount++;
        }
      } else {
        personalExpenses += transaction.amount;
        personalTransactionCount++;
      }
    }

    return UserTotalExpenseSummary(
      userId: userId,
      personalExpenses: personalExpenses,
      sharedExpenses: sharedExpenses,
      totalExpenses: personalExpenses + sharedExpenses,
      personalTransactionCount: personalTransactionCount,
      sharedTransactionCount: sharedTransactionCount,
    );
  }

  // Private validation methods
  Future<void> _validateTransactionInputs(double amount, int accountId, int categoryId) async {
    if (amount <= 0) {
      throw ArgumentError('Transaction amount must be positive');
    }

    final account = await _databaseHelper.getAccount(accountId);
    if (account == null || !account.isActive) {
      throw ArgumentError('Invalid or inactive account');
    }

    final category = await _databaseHelper.getCategory(categoryId);
    if (category == null || !category.isActive) {
      throw ArgumentError('Invalid or inactive category');
    }
  }

  Future<void> _validateSharedTransactionInputs(
    int groupId,
    Map<int, double> userShares,
    double totalAmount,
  ) async {
    final group = await _databaseHelper.getGroup(groupId);
    if (group == null || !group.isActive) {
      throw ArgumentError('Invalid or inactive group');
    }

    if (userShares.isEmpty) {
      throw ArgumentError('Shared transaction must have at least one user share');
    }

    // Validate that all users are members of the group
    final groupMembers = await _databaseHelper.getGroupMemberUsers(groupId);
    final memberIds = groupMembers.map((u) => u.id!).toSet();

    for (final userId in userShares.keys) {
      if (!memberIds.contains(userId)) {
        throw ArgumentError('User $userId is not a member of group $groupId');
      }
      
      if (userShares[userId]! <= 0) {
        throw ArgumentError('User share amount must be positive');
      }
    }

    // Validate that shares sum approximately to total amount
    final shareSum = userShares.values.reduce((a, b) => a + b);
    if ((shareSum - totalAmount.abs()).abs() > 0.01) {
      throw ArgumentError('Share amounts must sum to transaction amount');
    }
  }

  Future<void> _validatePercentageSplits(int groupId, Map<int, double> userPercentages) async {
    final group = await _databaseHelper.getGroup(groupId);
    if (group == null || !group.isActive) {
      throw ArgumentError('Invalid or inactive group');
    }

    if (userPercentages.isEmpty) {
      throw ArgumentError('Percentage splits must have at least one user');
    }

    // Validate that all users are members of the group
    final groupMembers = await _databaseHelper.getGroupMemberUsers(groupId);
    final memberIds = groupMembers.map((u) => u.id!).toSet();

    double totalPercentage = 0.0;
    for (final entry in userPercentages.entries) {
      if (!memberIds.contains(entry.key)) {
        throw ArgumentError('User ${entry.key} is not a member of group $groupId');
      }
      
      if (entry.value <= 0 || entry.value > 100) {
        throw ArgumentError('User percentage must be between 0 and 100');
      }
      
      totalPercentage += entry.value;
    }

    if ((totalPercentage - 100.0).abs() > 0.01) {
      throw ArgumentError('Percentage splits must sum to 100%');
    }
  }

  Future<void> _updateAccountBalanceForTransaction(Transaction transaction, [bool? isIncome]) async {
    final category = await _databaseHelper.getCategory(transaction.categoryId);
    if (category == null) return;

    // Determine if this is an income or expense transaction
    // Use explicit parameter if provided, otherwise fall back to category type
    final isIncomeTransaction = isIncome ?? (category.type == 'income');

    // For income transactions, add to account balance
    // For expense transactions, subtract from account balance
    final balanceChange = isIncomeTransaction
        ? transaction.amount 
        : -transaction.amount;

    await _accountService.adjustAccountBalance(transaction.accountId, balanceChange);
  }

  Future<void> _revertAccountBalanceForTransaction(Transaction transaction) async {
    final category = await _databaseHelper.getCategory(transaction.categoryId);
    if (category == null) return;

    // Reverse the balance change
    final balanceChange = category.type == 'income' 
        ? -transaction.amount 
        : transaction.amount;

    await _accountService.adjustAccountBalance(transaction.accountId, balanceChange);
  }

  // Enrich transactions with account, category, and split details
  Future<List<TransactionWithDetails>> _enrichTransactionsWithDetails(
    List<Transaction> transactions,
  ) async {
    final enriched = <TransactionWithDetails>[];

    for (final transaction in transactions) {
      final account = await _databaseHelper.getAccount(transaction.accountId);
      final category = await _databaseHelper.getCategory(transaction.categoryId);
      
      ExpenseGroup? group;
      List<SplitWithUser> splits = [];

      if (transaction.isShared && transaction.groupId != null) {
        group = await _databaseHelper.getGroup(transaction.groupId!);
        final rawSplits = await _databaseHelper.getSplitsForTransaction(transaction.id!);
        
        for (final split in rawSplits) {
          final user = await _databaseHelper.getUser(split.userId);
          if (user != null) {
            splits.add(SplitWithUser(split: split, user: user));
          }
        }
      }

      enriched.add(TransactionWithDetails(
        transaction: transaction,
        account: account,
        category: category,
        group: group,
        splits: splits,
      ));
    }

    return enriched;
  }
}

// Data classes for enriched transaction data
class TransactionWithDetails {
  final Transaction transaction;
  final Account? account;
  final Category? category;
  final ExpenseGroup? group;
  final List<SplitWithUser> splits;

  TransactionWithDetails({
    required this.transaction,
    required this.account,
    required this.category,
    this.group,
    this.splits = const [],
  });

  @override
  String toString() {
    return 'TransactionWithDetails(transaction: ${transaction.amount}, account: ${account?.name}, category: ${category?.name}, isShared: ${transaction.isShared})';
  }
}

class SplitWithUser {
  final Split split;
  final User user;

  SplitWithUser({
    required this.split,
    required this.user,
  });

  @override
  String toString() {
    return 'SplitWithUser(user: ${user.name}, amount: ${split.shareAmount}, percentage: ${split.sharePercentage}%)';
  }
}

class GroupExpenseSummary {
  final int groupId;
  final double totalAmount;
  final int transactionCount;
  final Map<int, UserExpenseSummary> userSummaries;

  GroupExpenseSummary({
    required this.groupId,
    required this.totalAmount,
    required this.transactionCount,
    required this.userSummaries,
  });

  @override
  String toString() {
    return 'GroupExpenseSummary(groupId: $groupId, totalAmount: $totalAmount, transactionCount: $transactionCount)';
  }
}

class UserExpenseSummary {
  final int userId;
  final double totalShare;
  final int transactionCount;

  UserExpenseSummary({
    required this.userId,
    required this.totalShare,
    required this.transactionCount,
  });

  @override
  String toString() {
    return 'UserExpenseSummary(userId: $userId, totalShare: $totalShare, transactionCount: $transactionCount)';
  }
}

class UserTotalExpenseSummary {
  final int userId;
  final double personalExpenses;
  final double sharedExpenses;
  final double totalExpenses;
  final int personalTransactionCount;
  final int sharedTransactionCount;

  UserTotalExpenseSummary({
    required this.userId,
    required this.personalExpenses,
    required this.sharedExpenses,
    required this.totalExpenses,
    required this.personalTransactionCount,
    required this.sharedTransactionCount,
  });

  @override
  String toString() {
    return 'UserTotalExpenseSummary(userId: $userId, personal: $personalExpenses, shared: $sharedExpenses, total: $totalExpenses)';
  }
}

// Extension for nullable firstOrNull (if not available in your Dart version)
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}