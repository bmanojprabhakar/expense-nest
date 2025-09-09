import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

// Custom database helper for testing
class TestDatabaseHelper {
  static const String dbName = ':memory:';
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await openDatabase(
      dbName,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create all tables
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

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

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE group_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        joined_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(group_id) REFERENCES expense_groups(id),
        FOREIGN KEY(user_id) REFERENCES users(id),
        UNIQUE(group_id, user_id)
      )
    ''');

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
        FOREIGN KEY(account_id) REFERENCES accounts(id),
        FOREIGN KEY(category_id) REFERENCES categories(id),
        FOREIGN KEY(group_id) REFERENCES expense_groups(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE splits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        share_amount REAL NOT NULL,
        share_percentage REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(transaction_id) REFERENCES transactions(id),
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

    // Insert test categories
    final categories = [
      {'name': 'Groceries', 'type': 'expense', 'icon': '🛒', 'is_default': 1},
      {'name': 'Food & Dining', 'type': 'expense', 'icon': '🍽️', 'is_default': 1},
      {'name': 'Travel', 'type': 'expense', 'icon': '✈️', 'is_default': 1},
      {'name': 'Salary', 'type': 'income', 'icon': '💰', 'is_default': 1},
    ];

    for (final category in categories) {
      await db.insert('categories', category);
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
import '../../lib/services/account_service.dart';
import '../../lib/services/group_service.dart';
import '../../lib/services/category_service.dart';
import '../../lib/services/transaction_service.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late AccountService accountService;
  late GroupService groupService;
  late CategoryService categoryService;
  late TransactionService transactionService;

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for testing
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create in-memory database for testing
    databaseHelper = DatabaseHelper();
    accountService = AccountService(databaseHelper);
    groupService = GroupService(databaseHelper);
    categoryService = CategoryService(databaseHelper);
    transactionService = TransactionService(databaseHelper, accountService);

    // Initialize database
    await databaseHelper.database;
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  group('Service Layer Integration Tests', () {
    test('should create account and retrieve it', () async {
      // Create an account
      final account = await accountService.createAccount(
        name: 'Test Bank Account',
        type: 'bank',
        initialBalance: 1000.0,
      );

      expect(account.id, isNotNull);
      expect(account.name, equals('Test Bank Account'));
      expect(account.type, equals('bank'));
      expect(account.balance, equals(1000.0));

      // Retrieve the account
      final retrievedAccount = await accountService.getAccountById(account.id!);
      expect(retrievedAccount, isNotNull);
      expect(retrievedAccount!.name, equals('Test Bank Account'));
    });

    test('should create users and groups', () async {
      // Create users
      final user1 = await groupService.createUser(name: 'John Doe');
      final user2 = await groupService.createUser(name: 'Jane Doe');

      expect(user1.id, isNotNull);
      expect(user2.id, isNotNull);

      // Create a group
      final group = await groupService.createGroup(
        name: 'Family',
        description: 'Family expenses',
        memberIds: [user1.id!, user2.id!],
      );

      expect(group.id, isNotNull);
      expect(group.name, equals('Family'));

      // Verify group members
      final members = await groupService.getGroupMembers(group.id!);
      expect(members.length, equals(2));
      expect(members.map((u) => u.name), containsAll(['John Doe', 'Jane Doe']));
    });

    test('should create personal transaction', () async {
      // Create account and category first
      final account = await accountService.createAccount(
        name: 'Cash',
        type: 'cash',
        initialBalance: 1000.0,
      );

      final categories = await categoryService.getExpenseCategories();
      final groceryCategory = categories.firstWhere(
        (c) => c.name.toLowerCase().contains('groceries'),
      );

      // Create personal transaction
      final transaction = await transactionService.createPersonalTransaction(
        amount: 50.0,
        date: DateTime.now(),
        accountId: account.id!,
        categoryId: groceryCategory.id!,
        note: 'Weekly groceries',
      );

      expect(transaction.id, isNotNull);
      expect(transaction.amount, equals(50.0));
      expect(transaction.isShared, isFalse);
      expect(transaction.note, equals('Weekly groceries'));

      // Check account balance was updated
      final updatedAccount = await accountService.getAccountById(account.id!);
      expect(updatedAccount!.balance, equals(950.0)); // 1000 - 50
    });

    test('should create shared transaction with equal splits', () async {
      // Create account
      final account = await accountService.createAccount(
        name: 'Cash',
        type: 'cash',
        initialBalance: 1000.0,
      );

      // Create users and group
      final user1 = await groupService.createUser(name: 'Alice');
      final user2 = await groupService.createUser(name: 'Bob');
      final group = await groupService.createGroup(
        name: 'Roommates',
        memberIds: [user1.id!, user2.id!],
      );

      // Get expense category
      final categories = await categoryService.getExpenseCategories();
      final diningCategory = categories.firstWhere(
        (c) => c.name.toLowerCase().contains('dining'),
      );

      // Create shared transaction with equal splits
      final transaction = await transactionService.createSharedTransactionEqualSplit(
        amount: 100.0,
        date: DateTime.now(),
        accountId: account.id!,
        categoryId: diningCategory.id!,
        groupId: group.id!,
        note: 'Dinner at restaurant',
      );

      expect(transaction.id, isNotNull);
      expect(transaction.amount, equals(100.0));
      expect(transaction.isShared, isTrue);
      expect(transaction.groupId, equals(group.id));

      // Check account balance
      final updatedAccount = await accountService.getAccountById(account.id!);
      expect(updatedAccount!.balance, equals(900.0)); // 1000 - 100

      // Retrieve transaction with details
      final transactionWithDetails = await transactionService.getTransactionById(transaction.id!);
      expect(transactionWithDetails, isNotNull);
      expect(transactionWithDetails!.splits.length, equals(2));
      
      // Each person should have 50.0 share
      for (final split in transactionWithDetails.splits) {
        expect(split.split.shareAmount, equals(50.0));
        expect(split.split.sharePercentage, equals(50.0));
      }
    });

    test('should create shared transaction with custom splits', () async {
      // Create account
      final account = await accountService.createAccount(
        name: 'Credit Card',
        type: 'credit_card',
        initialBalance: 0.0,
      );

      // Create users and group
      final user1 = await groupService.createUser(name: 'Charlie');
      final user2 = await groupService.createUser(name: 'Diana');
      final group = await groupService.createGroup(
        name: 'Couple',
        memberIds: [user1.id!, user2.id!],
      );

      // Get expense category
      final categories = await categoryService.getExpenseCategories();
      final travelCategory = categories.firstWhere(
        (c) => c.name.toLowerCase().contains('travel'),
      );

      // Create shared transaction with custom splits (70-30)
      final userShares = {
        user1.id!: 70.0, // Charlie pays more
        user2.id!: 30.0, // Diana pays less
      };

      final transaction = await transactionService.createSharedTransaction(
        amount: 100.0,
        date: DateTime.now(),
        accountId: account.id!,
        categoryId: travelCategory.id!,
        groupId: group.id!,
        userShares: userShares,
        note: 'Weekend trip',
      );

      expect(transaction.id, isNotNull);
      expect(transaction.amount, equals(100.0));
      expect(transaction.isShared, isTrue);

      // Verify splits
      final transactionWithDetails = await transactionService.getTransactionById(transaction.id!);
      expect(transactionWithDetails!.splits.length, equals(2));

      final charliesSplit = transactionWithDetails.splits.firstWhere(
        (s) => s.user.name == 'Charlie',
      );
      final dianasSplit = transactionWithDetails.splits.firstWhere(
        (s) => s.user.name == 'Diana',
      );

      expect(charliesSplit.split.shareAmount, equals(70.0));
      expect(charliesSplit.split.sharePercentage, equals(70.0));
      expect(dianasSplit.split.shareAmount, equals(30.0));
      expect(dianasSplit.split.sharePercentage, equals(30.0));
    });

    test('should get account summary', () async {
      // Create different types of accounts
      await accountService.createAccount(name: 'Cash', type: 'cash', initialBalance: 500.0);
      await accountService.createAccount(name: 'Bank', type: 'bank', initialBalance: 2000.0);
      await accountService.createAccount(name: 'Credit Card', type: 'credit_card', initialBalance: -100.0);

      final summary = await accountService.getAccountSummary();

      expect(summary.totalAccounts, equals(3));
      expect(summary.cashBalance, equals(500.0));
      expect(summary.bankBalance, equals(2000.0));
      expect(summary.creditBalance, equals(-100.0));
      expect(summary.totalBalance, equals(2400.0)); // 500 + 2000 + (-100)
    });

    test('should validate transaction inputs', () async {
      expect(
        () => transactionService.createPersonalTransaction(
          amount: -50.0, // Negative amount should fail
          date: DateTime.now(),
          accountId: 1,
          categoryId: 1,
        ),
        throwsArgumentError,
      );
    });

    test('should get category summary', () async {
      final summary = await categoryService.getCategorySummary();

      expect(summary.totalCategories, greaterThan(0));
      expect(summary.incomeCategories, greaterThan(0));
      expect(summary.expenseCategories, greaterThan(0));
      expect(summary.defaultCategories, greaterThan(0));
      expect(summary.customCategories, equals(0)); // No custom categories created yet
    });

    test('should search categories', () async {
      final searchResults = await categoryService.searchCategories(query: 'food');
      
      expect(searchResults, isNotEmpty);
      expect(
        searchResults.every((c) => c.name.toLowerCase().contains('food')), 
        isTrue,
      );
    });
  });
}