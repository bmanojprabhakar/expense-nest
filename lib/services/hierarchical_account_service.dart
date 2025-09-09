import '../data/database/database_helper.dart';
import '../data/models/account.dart';

class HierarchicalAccountService {
  final DatabaseHelper _databaseHelper;

  HierarchicalAccountService(this._databaseHelper);

  /// Build account tree structure from flat list
  Future<List<AccountNode>> buildAccountTree() async {
    final allAccounts = await _databaseHelper.getAllAccounts();
    
    // Create map for quick lookup
    final accountMap = <String, Account>{};
    final nodeMap = <String, AccountNode>{};
    
    for (final account in allAccounts) {
      accountMap[account.name] = account;
      nodeMap[account.name] = AccountNode(
        account: account,
        children: [],
      );
    }
    
    // Build tree structure
    final rootNodes = <AccountNode>[];
    
    for (final account in allAccounts) {
      final node = nodeMap[account.name]!;
      
      // If has parent (type refers to parent name)
      if (accountMap.containsKey(account.accountType)) {
        final parentNode = nodeMap[account.accountType]!;
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
  
  /// Calculate total balance including all children
  double _calculateAggregatedBalance(AccountNode node) {
    double total = node.account.balance;
    
    for (final child in node.children) {
      total += _calculateAggregatedBalance(child);
    }
    
    node.aggregatedBalance = total;
    return total;
  }
  
  /// Get all leaf nodes (actual accounts with transactions)
  List<Account> getLeafAccounts(List<AccountNode> tree) {
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
  
  /// Find account by ID in tree
  AccountNode? findAccountNode(List<AccountNode> tree, int accountId) {
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
  
  /// Get account path (breadcrumb)
  List<String> getAccountPath(AccountNode node) {
    final path = <String>[];
    AccountNode? current = node;
    
    while (current != null) {
      path.insert(0, current.account.name);
      current = current.parent;
    }
    
    return path;
  }
}

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