import '../data/database/database_helper.dart';
import '../data/models/account.dart';

class AccountService {
  final DatabaseHelper _databaseHelper;

  AccountService(this._databaseHelper);

  // Create a new account
  Future<Account> createAccount({
    required String name,
    int? parentId,
    String? accountType,
    double initialBalance = 0.0,
    int? statementDay,
    int? gracePeriodDays,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Account name cannot be empty');
    }

    // Validate parent exists if parentId is provided
    if (parentId != null) {
      final parent = await _databaseHelper.getAccount(parentId);
      if (parent == null) {
        throw ArgumentError('Parent account with ID $parentId not found');
      }
    }

    final account = Account(
      name: name.trim(),
      parentId: parentId,
      accountType: accountType,
      balance: initialBalance,
      createdAt: DateTime.now(),
      statementDay: statementDay,
      gracePeriodDays: gracePeriodDays,
    );

    final id = await _databaseHelper.insertAccount(account);
    return account.copyWith(id: id);
  }

  // Get all active accounts
  Future<List<Account>> getAllAccounts({bool includeInactive = false}) async {
    return await _databaseHelper.getAllAccounts(activeOnly: !includeInactive);
  }

  // Get account by ID
  Future<Account?> getAccountById(int id) async {
    return await _databaseHelper.getAccount(id);
  }

  // Get accounts by parent ID
  Future<List<Account>> getAccountsByParent(int? parentId) async {
    final allAccounts = await getAllAccounts();
    return allAccounts.where((account) => account.parentId == parentId).toList();
  }
  
  // Get root accounts (no parent)
  Future<List<Account>> getRootAccounts() async {
    return getAccountsByParent(null);
  }
  
  // Get child accounts of a parent
  Future<List<Account>> getChildAccounts(int parentId) async {
    return getAccountsByParent(parentId);
  }
  
  // Legacy method - Get accounts by type (for backward compatibility)
  Future<List<Account>> getAccountsByType(String accountType) async {
    final allAccounts = await getAllAccounts();
    return allAccounts.where((account) => account.accountType == accountType).toList();
  }

  // Update account details (name, type - not balance, that's handled by transactions)
  Future<Account> updateAccount({
    required int id,
    String? name,
    String? type,
  }) async {
    final existingAccount = await _databaseHelper.getAccount(id);
    if (existingAccount == null) {
      throw ArgumentError('Account with ID $id not found');
    }

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Account name cannot be empty');
    }

    // Note: We're no longer validating account types as they're now flexible
    
    final updatedAccount = existingAccount.copyWith(
      name: name?.trim() ?? existingAccount.name,
      accountType: type ?? existingAccount.accountType,
    );

    await _databaseHelper.updateAccount(updatedAccount);
    return updatedAccount;
  }

  // Comprehensive account update including credit card fields
  Future<Account> updateAccountComplete({
    required int id,
    String? name,
    String? type,
    double? balance,
    int? statementDay,
    int? gracePeriodDays,
  }) async {
    final existingAccount = await _databaseHelper.getAccount(id);
    if (existingAccount == null) {
      throw ArgumentError('Account with ID $id not found');
    }

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Account name cannot be empty');
    }

    final updatedAccount = existingAccount.copyWith(
      name: name?.trim() ?? existingAccount.name,
      accountType: type ?? existingAccount.accountType,
      balance: balance ?? existingAccount.balance,
      statementDay: statementDay ?? existingAccount.statementDay,
      gracePeriodDays: gracePeriodDays ?? existingAccount.gracePeriodDays,
    );

    await _databaseHelper.updateAccount(updatedAccount);
    return updatedAccount;
  }

  // Update account balance (typically called by TransactionService)
  Future<Account> updateAccountBalance(int accountId, double newBalance) async {
    final existingAccount = await _databaseHelper.getAccount(accountId);
    if (existingAccount == null) {
      throw ArgumentError('Account with ID $accountId not found');
    }

    final updatedAccount = existingAccount.copyWith(balance: newBalance);
    await _databaseHelper.updateAccount(updatedAccount);
    return updatedAccount;
  }

  // Adjust account balance (add or subtract amount)
  Future<Account> adjustAccountBalance(int accountId, double amount) async {
    final existingAccount = await _databaseHelper.getAccount(accountId);
    if (existingAccount == null) {
      throw ArgumentError('Account with ID $accountId not found');
    }

    final newBalance = existingAccount.balance + amount;
    return await updateAccountBalance(accountId, newBalance);
  }

  // Check if account can be deleted (no children, no transactions)
  Future<bool> canDeleteAccount(int id) async {
    // Check if account has children
    final children = await getChildAccounts(id);
    if (children.isNotEmpty) {
      return false;
    }
    
    return true;
  }
  
  // Delete account with validation
  Future<void> deleteAccount(int id) async {
    final existingAccount = await _databaseHelper.getAccount(id);
    if (existingAccount == null) {
      throw ArgumentError('Account with ID $id not found');
    }

    // Check if account can be deleted
    if (!(await canDeleteAccount(id))) {
      throw ArgumentError('Cannot delete account that has child accounts');
    }

    // Check if account has any transactions
    final hasTransactions = await _hasAccountTransactions(id);
    if (hasTransactions) {
      throw ArgumentError('Cannot delete account that has transactions');
    }

    // Safe to delete
    await _databaseHelper.deleteAccount(id);
  }

  // Deactivate account (soft delete)
  Future<void> deactivateAccount(int id) async {
    final existingAccount = await _databaseHelper.getAccount(id);
    if (existingAccount == null) {
      throw ArgumentError('Account with ID $id not found');
    }

    // Check if account has any transactions
    final hasTransactions = await _hasAccountTransactions(id);
    if (hasTransactions) {
      // Soft delete by marking as inactive
      final deactivatedAccount = existingAccount.copyWith(isActive: false);
      await _databaseHelper.updateAccount(deactivatedAccount);
    } else {
      // If no transactions, we could hard delete, but we'll keep it consistent
      await _databaseHelper.deleteAccount(id);
    }
  }

  // Reactivate account
  Future<Account> reactivateAccount(int id) async {
    final existingAccount = await _databaseHelper.getAccount(id);
    if (existingAccount == null) {
      throw ArgumentError('Account with ID $id not found');
    }

    final reactivatedAccount = existingAccount.copyWith(isActive: true);
    await _databaseHelper.updateAccount(reactivatedAccount);
    return reactivatedAccount;
  }

  // Get account balance history (would require transaction data)
  Future<double> calculateAccountBalance(int accountId) async {
    // This method calculates balance from transaction history
    // For now, we'll return the stored balance, but this could be enhanced
    // to calculate from actual transaction data for verification
    final account = await _databaseHelper.getAccount(accountId);
    return account?.balance ?? 0.0;
  }

  // Get total balance across all accounts
  Future<double> getTotalBalance({String? accountType}) async {
    final accounts = accountType != null 
        ? await getAccountsByType(accountType)
        : await getAllAccounts();
    
    return accounts.fold<double>(0.0, (total, account) => total + account.balance);
  }

  // Get account summary statistics
  Future<AccountSummary> getAccountSummary() async {
    final allAccounts = await getAllAccounts();
    
    final cashAccounts = allAccounts.where((a) => a.accountType == 'cash').toList();
    final bankAccounts = allAccounts.where((a) => a.accountType == 'bank').toList();
    final creditAccounts = allAccounts.where((a) => a.accountType == 'credit_card').toList();
    final savingsAccounts = allAccounts.where((a) => a.accountType == 'savings').toList();

    return AccountSummary(
      totalAccounts: allAccounts.length,
      totalBalance: allAccounts.fold(0.0, (sum, account) => sum + account.balance),
      cashBalance: cashAccounts.fold(0.0, (sum, account) => sum + account.balance),
      bankBalance: bankAccounts.fold(0.0, (sum, account) => sum + account.balance),
      creditBalance: creditAccounts.fold(0.0, (sum, account) => sum + account.balance),
      savingsBalance: savingsAccounts.fold(0.0, (sum, account) => sum + account.balance),
      accountsByType: {
        'cash': cashAccounts.length,
        'bank': bankAccounts.length,
        'credit_card': creditAccounts.length,
        'savings': savingsAccounts.length,
      },
    );
  }


  // Check if account has transactions (helper method)
  Future<bool> _hasAccountTransactions(int accountId) async {
    // Query the transactions table to check if this account has any transactions
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM transactions WHERE account_id = ?',
        [accountId]
      );
      
      final count = (result.first['count'] as int?) ?? 0;
      return count > 0;
    } catch (e) {
      // If there's an error (e.g., transactions table doesn't exist yet),
      // fall back to the balance check as a conservative approach
      final account = await _databaseHelper.getAccount(accountId);
      return account?.balance != 0.0;
    }
  }

  // Build hierarchical account tree
  Future<List<AccountNode>> buildAccountTree() async {
    final allAccounts = await getAllAccounts();
    
    // Create map for quick lookup
    final nodeMap = <int, AccountNode>{};
    
    // Create all nodes first
    for (final account in allAccounts) {
      nodeMap[account.id!] = AccountNode(
        account: account,
        children: [],
      );
    }
    
    // Build tree structure
    final rootNodes = <AccountNode>[];
    
    for (final account in allAccounts) {
      final node = nodeMap[account.id!]!;
      
      if (account.parentId != null && nodeMap.containsKey(account.parentId)) {
        // Add to parent's children
        final parentNode = nodeMap[account.parentId!]!;
        parentNode.children.add(node);
        node.parent = parentNode;
      } else {
        // Root level node
        rootNodes.add(node);
      }
    }
    
    // Calculate aggregated balances
    for (final rootNode in rootNodes) {
      _calculateAggregatedBalance(rootNode);
    }
    
    return rootNodes;
  }
  
  // Calculate total balance including all children
  double _calculateAggregatedBalance(AccountNode node) {
    // For leaf nodes (actual accounts), use their balance
    if (node.children.isEmpty) {
      node.aggregatedBalance = node.account.balance;
      return node.account.balance;
    }
    
    // For parent nodes, sum all children
    double total = 0.0;
    for (final child in node.children) {
      total += _calculateAggregatedBalance(child);
    }
    
    node.aggregatedBalance = total;
    return total;
  }
  
  // Get all leaf accounts (actual accounts that can have transactions)
  Future<List<Account>> getLeafAccounts() async {
    final tree = await buildAccountTree();
    final leafAccounts = <Account>[];
    
    void collectLeaves(AccountNode node) {
      if (node.children.isEmpty) {
        leafAccounts.add(node.account);
      } else {
        for (final child in node.children) {
          collectLeaves(child);
        }
      }
    }
    
    for (final root in tree) {
      collectLeaves(root);
    }
    
    return leafAccounts;
  }
  
  // Get account path (breadcrumb)
  Future<List<String>> getAccountPath(int accountId) async {
    final tree = await buildAccountTree();
    final node = _findAccountNode(tree, accountId);
    
    if (node == null) return [];
    
    final path = <String>[];
    AccountNode? current = node;
    
    while (current != null) {
      path.insert(0, current.account.name);
      current = current.parent;
    }
    
    return path;
  }
  
  // Find account node in tree
  AccountNode? _findAccountNode(List<AccountNode> tree, int accountId) {
    AccountNode? search(AccountNode node) {
      if (node.account.id == accountId) return node;
      
      for (final child in node.children) {
        final found = search(child);
        if (found != null) return found;
      }
      return null;
    }
    
    for (final root in tree) {
      final found = search(root);
      if (found != null) return found;
    }
    return null;
  }

  // Get valid account types
  List<String> getValidAccountTypes() {
    return ['cash', 'bank', 'credit_card', 'savings'];
  }

  // Get account type display names
  Map<String, String> getAccountTypeDisplayNames() {
    return {
      'cash': 'Cash',
      'bank': 'Bank Account',
      'credit_card': 'Credit Card',
      'savings': 'Savings Account',
    };
  }
}

// AccountNode class for tree structure
class AccountNode {
  final Account account;
  final List<AccountNode> children;
  AccountNode? parent;
  double aggregatedBalance;
  
  AccountNode({
    required this.account,
    required this.children,
    this.parent,
    this.aggregatedBalance = 0.0,
  });
  
  /// Check if this is a leaf node (actual account)
  bool get isLeaf => children.isEmpty;
  
  /// Check if this is a root node
  bool get isRoot => parent == null;
  
  /// Get depth in tree (0 = root)
  int get depth {
    int d = 0;
    AccountNode? current = parent;
    while (current != null) {
      d++;
      current = current.parent;
    }
    return d;
  }
}

// Data class for account summary
class AccountSummary {
  final int totalAccounts;
  final double totalBalance;
  final double cashBalance;
  final double bankBalance;
  final double creditBalance;
  final double savingsBalance;
  final Map<String, int> accountsByType;

  AccountSummary({
    required this.totalAccounts,
    required this.totalBalance,
    required this.cashBalance,
    required this.bankBalance,
    required this.creditBalance,
    required this.savingsBalance,
    required this.accountsByType,
  });

  @override
  String toString() {
    return 'AccountSummary(totalAccounts: $totalAccounts, totalBalance: $totalBalance, '
           'cashBalance: $cashBalance, bankBalance: $bankBalance, creditBalance: $creditBalance, '
           'savingsBalance: $savingsBalance, accountsByType: $accountsByType)';
  }
}