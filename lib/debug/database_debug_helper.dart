import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/database/database_helper.dart';
import '../services/simple_data_init.dart';

class DatabaseDebugHelper {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get the database file path
  static Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return '${documentsDirectory.path}/family_expense_manager.db';
  }

  /// Export database file for external viewing
  static Future<void> exportDatabase() async {
    try {
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);
      
      if (await dbFile.exists()) {
        // Share the database file
        await Share.shareXFiles(
          [XFile(dbPath)],
          text: 'SQLite Database Export',
          subject: 'family_expense_manager.db',
        );
        print('Database exported successfully from: $dbPath');
      } else {
        print('Database file not found at: $dbPath');
      }
    } catch (e) {
      print('Error exporting database: $e');
    }
  }

  /// Print all account data to console
  static Future<void> printAllAccounts() async {
    try {
      final db = await _dbHelper.database;
      final accounts = await db.query('accounts');
      
      print('\n=== ACCOUNTS TABLE ===');
      print('ID | Name                    | Type        | Balance    | Created At          | Active');
      print('---|-------------------------|-------------|------------|---------------------|-------');
      
      for (final account in accounts) {
        print('${account['id'].toString().padRight(2)} | '
            '${account['name'].toString().padRight(23)} | '
            '${account['type'].toString().padRight(11)} | '
            '₹${account['balance'].toString().padLeft(9)} | '
            '${account['created_at'].toString().substring(0, 19)} | '
            '${account['is_active'] == 1 ? 'Yes' : 'No'}');
      }
      print('\nTotal accounts: ${accounts.length}\n');
    } catch (e) {
      print('Error reading accounts: $e');
    }
  }

  /// Print all transactions
  static Future<void> printAllTransactions() async {
    try {
      final db = await _dbHelper.database;
      final transactions = await db.rawQuery('''
        SELECT t.*, a.name as account_name, c.name as category_name
        FROM transactions t
        LEFT JOIN accounts a ON t.account_id = a.id
        LEFT JOIN categories c ON t.category_id = c.id
        ORDER BY t.date DESC
        LIMIT 20
      ''');
      
      print('\n=== RECENT TRANSACTIONS (Last 20) ===');
      print('ID | Amount    | Date       | Account              | Category      | Note');
      print('---|-----------|------------|----------------------|---------------|-----');
      
      for (final txn in transactions) {
        print('${txn['id'].toString().padRight(2)} | '
            '₹${txn['amount'].toString().padLeft(8)} | '
            '${txn['date'].toString().substring(0, 10)} | '
            '${(txn['account_name'] ?? 'Unknown').toString().padRight(20)} | '
            '${(txn['category_name'] ?? 'Unknown').toString().padRight(13)} | '
            '${txn['note'] ?? ''}');
      }
      print('\n');
    } catch (e) {
      print('Error reading transactions: $e');
    }
  }

  /// Get database statistics
  static Future<void> printDatabaseStats() async {
    try {
      final db = await _dbHelper.database;
      
      final accountCount = await db.rawQuery('SELECT COUNT(*) as count FROM accounts WHERE is_active = 1');
      final transactionCount = await db.rawQuery('SELECT COUNT(*) as count FROM transactions');
      final categoryCount = await db.rawQuery('SELECT COUNT(*) as count FROM categories WHERE is_active = 1');
      
      final totalAssets = await db.rawQuery('SELECT SUM(balance) as total FROM accounts WHERE balance > 0 AND is_active = 1');
      final totalLiabilities = await db.rawQuery('SELECT SUM(ABS(balance)) as total FROM accounts WHERE balance < 0 AND is_active = 1');
      
      print('\n=== DATABASE STATISTICS ===');
      print('Active Accounts: ${accountCount.first['count']}');
      print('Total Transactions: ${transactionCount.first['count']}');
      print('Active Categories: ${categoryCount.first['count']}');
      final assets = (totalAssets.first['total'] as double?) ?? 0.0;
      final liabilities = (totalLiabilities.first['total'] as double?) ?? 0.0;
      print('Total Assets: ₹${assets.toStringAsFixed(2)}');
      print('Total Liabilities: ₹${liabilities.toStringAsFixed(2)}');
      print('Net Worth: ₹${(assets - liabilities).toStringAsFixed(2)}');
      print('');
    } catch (e) {
      print('Error getting database stats: $e');
    }
  }

  /// Execute custom SQL query (READ ONLY)
  static Future<void> executeQuery(String query) async {
    if (query.trim().toLowerCase().startsWith('select')) {
      try {
        final db = await _dbHelper.database;
        final results = await db.rawQuery(query);
        
        print('\n=== QUERY RESULTS ===');
        if (results.isEmpty) {
          print('No results found.');
        } else {
          // Print headers
          final headers = results.first.keys.toList();
          print(headers.join(' | '));
          print(headers.map((h) => '-' * h.length).join('-|-'));
          
          // Print rows
          for (final row in results) {
            print(row.values.map((v) => v.toString()).join(' | '));
          }
        }
        print('\nTotal results: ${results.length}\n');
      } catch (e) {
        print('Error executing query: $e');
      }
    } else {
      print('Only SELECT queries are allowed for safety.');
    }
  }

  /// Run all debug reports
  static Future<void> runFullDebugReport() async {
    print('\n🔍 RUNNING FULL DATABASE DEBUG REPORT 🔍\n');
    
    await printDatabaseStats();
    await printAllAccounts();
    await printAllTransactions();
    
    final dbPath = await getDatabasePath();
    print('📍 Database location: $dbPath');
    print('\n✅ Debug report complete!\n');
  }

  /// DANGER: Reset the entire database and reinitialize with sample data
  /// This will DELETE ALL existing data permanently!
  static Future<void> resetDatabaseCompletely() async {
    print('\n⚠️  WARNING: This will DELETE ALL DATA! ⚠️');
    print('🔥 Resetting database in 3 seconds...');
    
    // Give a moment to see the warning
    await Future.delayed(const Duration(seconds: 3));
    
    try {
      // Reset the database
      await _dbHelper.resetDatabase();
      
      // Reinitialize with sample data
      print('🔄 Reinitializing with sample data...');
      await SimpleDataInit.initializeBasicData();
      
      print('\n✅ DATABASE RESET COMPLETE!');
      print('✅ Sample data has been reinitialized');
      print('✅ You can now test the app with fresh data\n');
    } catch (e) {
      print('❌ Error during database reset: $e');
      rethrow;
    }
  }

  /// Clear all data but keep schema intact, then reinitialize
  static Future<void> clearAndReinitializeData() async {
    print('\n🧹 Clearing all data and reinitializing...');
    
    try {
      // Clear all data
      await _dbHelper.clearAllData();
      
      // Reinitialize with sample data
      print('🔄 Adding fresh sample data...');
      await SimpleDataInit.initializeBasicData();
      
      print('\n✅ DATA CLEARED AND REINITIALIZED!');
      print('✅ Fresh sample data has been added');
      print('✅ Database schema preserved\n');
    } catch (e) {
      print('❌ Error during data reset: $e');
      rethrow;
    }
  }

  /// Quick diagnostic method to check for common database issues
  static Future<void> diagnosticCheck() async {
    print('\n🔍 RUNNING DATABASE DIAGNOSTIC CHECK 🔍');
    
    try {
      final db = await _dbHelper.database;
      
      // Check if database is accessible
      final result = await db.rawQuery('SELECT 1');
      print('✅ Database connection: OK');
      
      // Check table counts
      final accounts = await db.rawQuery('SELECT COUNT(*) as count FROM accounts');
      final transactions = await db.rawQuery('SELECT COUNT(*) as count FROM transactions'); 
      final categories = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
      
      print('📊 Accounts: ${accounts.first['count']}');
      print('📊 Transactions: ${transactions.first['count']}');  
      print('📊 Categories: ${categories.first['count']}');
      
      // Check for any locked transactions
      final lockCheck = await db.rawQuery('PRAGMA journal_mode');
      print('🔒 Journal mode: ${lockCheck.first.values.first}');
      
      print('✅ Diagnostic check complete - no obvious issues detected\n');
    } catch (e) {
      print('❌ Diagnostic check failed: $e');
      print('💡 Consider running resetDatabaseCompletely() to fix issues\n');
    }
  }
}