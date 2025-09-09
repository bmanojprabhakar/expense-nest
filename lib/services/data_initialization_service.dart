import '../services/category_service.dart';
import '../services/account_service.dart';
import '../services/group_service.dart';
import '../data/database/database_helper.dart';
import '../data/models/account.dart';

/// Service to initialize the database with sample data for testing
class DataInitializationService {
  late final DatabaseHelper _databaseHelper;
  late final CategoryService _categoryService;
  late final AccountService _accountService;
  late final GroupService _groupService;
  
  DataInitializationService() {
    _databaseHelper = DatabaseHelper();
    _categoryService = CategoryService(_databaseHelper);
    _accountService = AccountService(_databaseHelper);
    _groupService = GroupService(_databaseHelper);
  }

  /// Initialize the database with sample data if it's empty
  Future<void> initializeIfEmpty() async {
    // Check if data already exists
    final accounts = await _accountService.getAllAccounts();
    if (accounts.isNotEmpty) {
      return; // Already initialized
    }

    print('Initializing database with sample data...');

    // Initialize categories (this will create default categories automatically)
    await _categoryService.getExpenseCategories();
    await _categoryService.getIncomeCategories();

    // Create sample accounts
    await _createSampleAccounts();

    // Create sample users and groups
    await _createSampleUsersAndGroups();

    print('Database initialization complete!');
  }

  Future<void> _createSampleAccounts() async {
    final accounts = [
      Account(
        name: 'Checking Account',
        accountType: 'bank',
        balance: 2500.00,
        createdAt: DateTime.now(),
      ),
      Account(
        name: 'Savings Account',
        accountType: 'savings', 
        balance: 15000.00,
        createdAt: DateTime.now(),
      ),
      Account(
        name: 'Cash Wallet',
        accountType: 'cash',
        balance: 500.00,
        createdAt: DateTime.now(),
      ),
      Account(
        name: 'Credit Card',
        accountType: 'credit_card',
        balance: -1200.00,
        createdAt: DateTime.now(),
      ),
    ];

    for (final account in accounts) {
      await _accountService.createAccount(
        name: account.name,
        accountType: account.accountType,
        initialBalance: account.balance,
      );
    }
  }

  Future<void> _createSampleUsersAndGroups() async {
    // Create main user (you)
    final mainUserId = await _groupService.createUser(
      name: 'You',
      email: 'you@example.com',
    );

    // Create other family members
    final spouseUserId = await _groupService.createUser(
      name: 'Spouse',
      email: 'spouse@example.com',
    );

    final child1UserId = await _groupService.createUser(
      name: 'Child 1', 
      email: 'child1@example.com',
    );

    final child2UserId = await _groupService.createUser(
      name: 'Child 2',
      email: 'child2@example.com',
    );

    // Create Family group
    final familyGroupId = await _groupService.createGroup(
      name: 'Family',
      description: 'Family expenses shared among all members',
    );
    
    // Add all family members to family group
    await _groupService.addUserToGroup(familyGroupId.id!, mainUserId.id!);
    await _groupService.addUserToGroup(familyGroupId.id!, spouseUserId.id!);
    await _groupService.addUserToGroup(familyGroupId.id!, child1UserId.id!);
    await _groupService.addUserToGroup(familyGroupId.id!, child2UserId.id!);

    // Create Spouse group
    final spouseGroupId = await _groupService.createGroup(
      name: 'Spouse',
      description: 'Expenses shared between spouses',
    );
    
    // Add main user and spouse to spouse group
    await _groupService.addUserToGroup(spouseGroupId.id!, mainUserId.id!);
    await _groupService.addUserToGroup(spouseGroupId.id!, spouseUserId.id!);

    // Create Roommates group (sample)
    final roommateUserId = await _groupService.createUser(
      name: 'Roommate',
      email: 'roommate@example.com',
    );

    final roommatesGroupId = await _groupService.createGroup(
      name: 'Roommates',
      description: 'Shared living expenses',
    );
    
    await _groupService.addUserToGroup(roommatesGroupId.id!, mainUserId.id!);
    await _groupService.addUserToGroup(roommatesGroupId.id!, roommateUserId.id!);
  }
}