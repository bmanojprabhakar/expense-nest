import '../data/database/database_helper.dart';
import '../data/models/account.dart';

/// Sample data initialization for testing
class SimpleDataInit {
  static final DatabaseHelper _db = DatabaseHelper();

  /// Initialize basic test data if accounts table is empty
  static Future<void> initializeBasicData() async {
    try {
      // Check if we already have accounts
      final accounts = await _db.getAllAccounts();
      if (accounts.isNotEmpty) {
        print('Data already initialized. Found ${accounts.length} accounts.');
        return;
      }

      print('Initializing basic test data...');

      print('Creating hierarchical account structure...');
      
      // Step 1: Create root level accounts
      final rootAccounts = <String, int>{};
      
      final rootAccountData = [
        {'name': 'Cash', 'type': 'cash'},
        {'name': 'Bank Account', 'type': 'bank'},
        {'name': 'Cards', 'type': 'card'},
        {'name': 'Wallet', 'type': 'wallet'},
      ];
      
      for (final accountData in rootAccountData) {
        final account = Account(
          name: accountData['name']!,
          parentId: null,
          accountType: accountData['type'],
          balance: 0.0, // Root accounts have calculated balances
          createdAt: DateTime.now(),
        );
        final id = await _db.insertAccount(account);
        rootAccounts[account.name] = id;
        print('Created root account: ${account.name} (id: $id)');
      }
      
      // Step 2: Create second level accounts
      final secondLevelAccounts = <String, int>{};
      
      final secondLevelData = [
        {'name': 'Savings Account', 'parent': 'Bank Account', 'type': 'savings'},
        {'name': 'Current Account', 'parent': 'Bank Account', 'type': 'checking'},
        {'name': 'Credit Cards', 'parent': 'Cards', 'type': 'credit'},
        {'name': 'Debit Cards', 'parent': 'Cards', 'type': 'debit'},
        {'name': 'Meal Cards', 'parent': 'Cards', 'type': 'meal'},
      ];
      
      for (final accountData in secondLevelData) {
        final parentId = rootAccounts[accountData['parent']!];
        final account = Account(
          name: accountData['name']!,
          parentId: parentId,
          accountType: accountData['type'],
          balance: 0.0, // Parent accounts have calculated balances
          createdAt: DateTime.now(),
        );
        final id = await _db.insertAccount(account);
        secondLevelAccounts[account.name] = id;
        print('Created second level account: ${account.name} (parent: $parentId, id: $id)');
      }
      
      // Step 3: Create leaf accounts (actual bank accounts with real balances)
      final leafAccountData = [
        // Savings accounts
        {'name': 'ICICI', 'parent': 'Savings Account', 'balance': 14000.0},
        {'name': 'HDFC', 'parent': 'Savings Account', 'balance': 0.0},
        
        // Current account
        {'name': 'Current Account Main', 'parent': 'Current Account', 'balance': 300.0},
        
        // Credit cards (negative balances = liabilities)
        {'name': 'IndusInd', 'parent': 'Credit Cards', 'balance': -800.0},
        {'name': 'Axis', 'parent': 'Credit Cards', 'balance': -400.0},
        
        // Cash wallet
        {'name': 'My Wallet', 'parent': 'Cash', 'balance': 2400.0},
        
        // Digital wallets
        {'name': 'Amazon Pay', 'parent': 'Wallet', 'balance': 150.0},
        {'name': 'PhonePe', 'parent': 'Wallet', 'balance': 250.0},
      ];
      
      for (final accountData in leafAccountData) {
        final parentId = secondLevelAccounts[accountData['parent']] ?? rootAccounts[accountData['parent']];
        final account = Account(
          name: accountData['name']! as String,
          parentId: parentId,
          accountType: 'leaf',
          balance: (accountData['balance'] as num).toDouble(),
          createdAt: DateTime.now(),
        );
        final id = await _db.insertAccount(account);
        print('Created leaf account: ${account.name} (parent: $parentId, balance: ${account.balance}, id: $id)');
      }

      print('Hierarchical account structure created successfully!');
      print('- Created ${rootAccountData.length} root accounts');
      print('- Created ${secondLevelData.length} second level accounts');
      print('- Created ${leafAccountData.length} leaf accounts');
      print('- Default categories are auto-created by database');

    } catch (e) {
      print('Error initializing test data: $e');
    }
  }
}