import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/transaction.dart' as app_transaction show Transaction;
import '../models/split.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'family_expense_manager.db');
    
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create accounts table with hierarchical support
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        account_type TEXT,
        balance REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        statement_day INTEGER,
        grace_period_days INTEGER,
        FOREIGN KEY(parent_id) REFERENCES accounts(id) ON DELETE RESTRICT
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create expense_groups table
    await db.execute('''
      CREATE TABLE expense_groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create group_members table (many-to-many relationship)
    await db.execute('''
      CREATE TABLE group_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        joined_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(group_id) REFERENCES expense_groups(id) ON DELETE CASCADE,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(group_id, user_id)
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        description TEXT,
        account_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        is_shared INTEGER NOT NULL DEFAULT 0,
        group_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT,
        FOREIGN KEY(group_id) REFERENCES expense_groups(id) ON DELETE SET NULL
      )
    ''');

    // Create splits table
    await db.execute('''
      CREATE TABLE splits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        share_amount REAL NOT NULL,
        share_percentage REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE RESTRICT,
        UNIQUE(transaction_id, user_id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_account ON transactions(account_id)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id)');
    await db.execute('CREATE INDEX idx_transactions_group ON transactions(group_id)');
    await db.execute('CREATE INDEX idx_splits_transaction ON splits(transaction_id)');
    await db.execute('CREATE INDEX idx_splits_user ON splits(user_id)');
    await db.execute('CREATE INDEX idx_group_members_group ON group_members(group_id)');
    await db.execute('CREATE INDEX idx_group_members_user ON group_members(user_id)');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      // Migration from version 1 to 2: Add hierarchical support to accounts
      print('Migrating database from version $oldVersion to $newVersion');
      
      try {
        // For this migration, we'll recreate the accounts table with proper hierarchy
        // Backup existing accounts
        final existingAccounts = await db.query('accounts');
        print('Backing up ${existingAccounts.length} existing accounts');
        
        // Drop and recreate accounts table
        await db.execute('DROP TABLE IF EXISTS accounts');
        
        await db.execute('''
          CREATE TABLE accounts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            parent_id INTEGER,
            account_type TEXT,
            balance REAL NOT NULL DEFAULT 0.0,
            created_at TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            statement_day INTEGER,
            payment_due_day INTEGER,
            FOREIGN KEY(parent_id) REFERENCES accounts(id) ON DELETE RESTRICT
          )
        ''');
        
        print('Created new hierarchical accounts table');
        
        // Note: Sample data will be recreated by SimpleDataInit
        
      } catch (e) {
        print('Migration failed: $e');
        rethrow;
      }
    } else if (oldVersion < 3 && newVersion >= 3) {
      // Migration from version 2 to 3: Add credit card specific fields (deprecated - skip to v4)
      print('Migrating database from version $oldVersion to $newVersion (skipping to v4)');
      
      try {
        await db.execute('ALTER TABLE accounts ADD COLUMN statement_day INTEGER');
        await db.execute('ALTER TABLE accounts ADD COLUMN payment_due_day INTEGER');
        print('Added credit card day fields to accounts table');
      } catch (e) {
        print('Migration failed: $e');
        rethrow;
      }
    } else if (oldVersion < 4 && newVersion >= 4) {
      // Migration from version 3 to 4: Convert date fields to day fields
      print('Migrating database from version $oldVersion to $newVersion');
      
      try {
        // If we have the old date fields, drop them and add new day fields
        await db.execute('ALTER TABLE accounts ADD COLUMN statement_day INTEGER').catchError((_) {});
        await db.execute('ALTER TABLE accounts ADD COLUMN payment_due_day INTEGER').catchError((_) {});
        print('Added credit card day fields to accounts table');
      } catch (e) {
        print('Migration failed: $e');
        rethrow;
      }
    } else if (oldVersion < 5 && newVersion >= 5) {
      // Migration from version 4 to 5: Rename payment_due_day to grace_period_days
      print('Migrating database from version $oldVersion to $newVersion');
      
      try {
        // Add new column
        await db.execute('ALTER TABLE accounts ADD COLUMN grace_period_days INTEGER').catchError((_) {});
        // Copy data from old column if it exists
        await db.execute('UPDATE accounts SET grace_period_days = payment_due_day WHERE payment_due_day IS NOT NULL').catchError((_) {});
        print('Added grace_period_days column and migrated data');
      } catch (e) {
        print('Migration failed: $e');
        rethrow;
      }
    } else if (oldVersion < newVersion) {
      // For other version upgrades, recreate everything
      await db.execute('DROP TABLE IF EXISTS splits');
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS group_members');
      await db.execute('DROP TABLE IF EXISTS expense_groups');
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS accounts');
      
      await _onCreate(db, newVersion);
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final batch = db.batch();
    
    // Insert default expense categories
    for (final category in Category.getDefaultExpenseCategories()) {
      batch.insert('categories', category.toMap());
    }
    
    // Insert default income categories
    for (final category in Category.getDefaultIncomeCategories()) {
      batch.insert('categories', category.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  // CRUD operations for Accounts
  Future<int> insertAccount(Account account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAllAccounts({bool activeOnly = true}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<Account?> getAccount(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAccount(Account account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.update(
      'accounts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Categories
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories({bool activeOnly = true, String? type}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    
    if (activeOnly && type != null) {
      where = 'is_active = ? AND type = ?';
      whereArgs = [1, type];
    } else if (activeOnly) {
      where = 'is_active = ?';
      whereArgs = [1];
    } else if (type != null) {
      where = 'type = ?';
      whereArgs = [type];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getCategory(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.update(
      'categories',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Users
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getAllUsers({bool activeOnly = true}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.update(
      'users',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Groups
  Future<int> insertGroup(ExpenseGroup group) async {
    final db = await database;
    return await db.insert('expense_groups', group.toMap());
  }

  Future<List<ExpenseGroup>> getAllGroups({bool activeOnly = true}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_groups',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => ExpenseGroup.fromMap(maps[i]));
  }

  Future<ExpenseGroup?> getGroup(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ExpenseGroup.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateGroup(ExpenseGroup group) async {
    final db = await database;
    return await db.update(
      'expense_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await database;
    return await db.update(
      'expense_groups',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Group Members
  Future<int> insertGroupMember(GroupMember member) async {
    final db = await database;
    return await db.insert('group_members', member.toMap());
  }

  Future<List<GroupMember>> getGroupMembers(int groupId, {bool activeOnly = true}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'group_members',
      where: activeOnly ? 'group_id = ? AND is_active = ?' : 'group_id = ?',
      whereArgs: activeOnly ? [groupId, 1] : [groupId],
      orderBy: 'joined_at ASC',
    );
    return List.generate(maps.length, (i) => GroupMember.fromMap(maps[i]));
  }

  Future<List<User>> getGroupMemberUsers(int groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN group_members gm ON u.id = gm.user_id
      WHERE gm.group_id = ? AND gm.is_active = 1 AND u.is_active = 1
      ORDER BY u.name ASC
    ''', [groupId]);
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<int> removeUserFromGroup(int groupId, int userId) async {
    final db = await database;
    return await db.update(
      'group_members',
      {'is_active': 0},
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
  }

  // CRUD operations for Transactions
  Future<int> insertTransaction(app_transaction.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<app_transaction.Transaction>> getTransactionsForMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC, created_at DESC',
    );
    return List.generate(maps.length, (i) => app_transaction.Transaction.fromMap(maps[i]));
  }

  Future<List<app_transaction.Transaction>> getTransactionsForDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC, created_at DESC',
    );
    return List.generate(maps.length, (i) => app_transaction.Transaction.fromMap(maps[i]));
  }

  Future<app_transaction.Transaction?> getTransaction(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return app_transaction.Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransaction(app_transaction.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Splits
  Future<int> insertSplit(Split split) async {
    final db = await database;
    return await db.insert('splits', split.toMap());
  }

  Future<List<Split>> getSplitsForTransaction(int transactionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'splits',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'share_percentage DESC',
    );
    return List.generate(maps.length, (i) => Split.fromMap(maps[i]));
  }

  Future<int> deleteSplitsForTransaction(int transactionId) async {
    final db = await database;
    return await db.delete(
      'splits',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  // Complex transaction with splits (atomic operation)
  Future<int> insertTransactionWithSplits(app_transaction.Transaction transaction, List<Split> splits) async {
    final db = await database;
    late int transactionId;
    
    await db.transaction((txn) async {
      // Insert the main transaction
      transactionId = await txn.insert('transactions', transaction.toMap());
      
      // Insert all splits with the transaction ID
      for (final split in splits) {
        final splitWithTransactionId = split.copyWith(transactionId: transactionId);
        await txn.insert('splits', splitWithTransactionId.toMap());
      }
    });
    
    return transactionId;
  }

  Future<void> updateTransactionWithSplits(app_transaction.Transaction transaction, List<Split> splits) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Update the main transaction
      await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      
      // Delete existing splits
      await txn.delete(
        'splits',
        where: 'transaction_id = ?',
        whereArgs: [transaction.id],
      );
      
      // Insert new splits
      for (final split in splits) {
        await txn.insert('splits', split.toMap());
      }
    });
  }

  // Utility method to close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Method to get database file path (useful for backups)
  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'family_expense_manager.db');
  }

  /// Reset the entire database by dropping all tables and recreating them
  /// This will delete ALL data and reinitialize with fresh schema
  Future<void> resetDatabase() async {
    print('🔥 RESETTING DATABASE - ALL DATA WILL BE LOST 🔥');
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    // Get database path and delete the file completely
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);
    
    if (await dbFile.exists()) {
      await dbFile.delete();
      print('✅ Deleted existing database file: $dbPath');
    }
    
    // Reinitialize database (this will create fresh tables)
    _database = await _initDatabase();
    print('✅ Database reset complete with fresh schema');
  }

  /// Clear all data from tables without recreating schema
  /// This preserves the table structure but removes all records
  Future<void> clearAllData() async {
    final db = await database;
    
    print('🧹 Clearing all data from database...');
    
    await db.transaction((txn) async {
      // Delete in order respecting foreign key constraints
      await txn.execute('DELETE FROM splits');
      await txn.execute('DELETE FROM transactions');
      await txn.execute('DELETE FROM group_members');
      await txn.execute('DELETE FROM expense_groups');
      await txn.execute('DELETE FROM users');
      await txn.execute('DELETE FROM categories');
      await txn.execute('DELETE FROM accounts');
      
      // Reset any auto-increment counters
      await txn.execute('DELETE FROM sqlite_sequence WHERE name IN ("accounts", "categories", "users", "expense_groups", "group_members", "transactions", "splits")');
    });
    
    print('✅ All data cleared successfully');
  }

  /// Reset database and reinitialize with sample data
  Future<void> resetAndReinitialize() async {
    await resetDatabase();
    
    // Initialize sample data - import will be handled by the caller
    print('✅ Database reset complete - call SimpleDataInit.initializeBasicData() to add sample data');
  }
}