import 'package:flutter_test/flutter_test.dart';
import '../lib/data/models/account.dart';
import '../lib/data/models/category.dart';
import '../lib/data/models/user.dart';
import '../lib/data/models/group.dart';
import '../lib/data/models/transaction.dart';
import '../lib/data/models/split.dart';

void main() {
  group('Data Models Tests', () {
    test('should create account model', () {
      final account = Account(
        name: 'Test Account',
        type: 'bank',
        balance: 1000.0,
        createdAt: DateTime.now(),
      );

      expect(account.name, equals('Test Account'));
      expect(account.type, equals('bank'));
      expect(account.balance, equals(1000.0));
      expect(account.isActive, isTrue);

      final map = account.toMap();
      expect(map['name'], equals('Test Account'));
      expect(map['type'], equals('bank'));
      expect(map['balance'], equals(1000.0));

      final recreated = Account.fromMap(map);
      expect(recreated.name, equals(account.name));
      expect(recreated.type, equals(account.type));
      expect(recreated.balance, equals(account.balance));
    });

    test('should create category model with defaults', () {
      final expenseCategories = Category.getDefaultExpenseCategories();
      expect(expenseCategories.length, greaterThan(10));
      
      final grocery = expenseCategories.firstWhere((c) => c.name.contains('Groceries'));
      expect(grocery.type, equals('expense'));
      expect(grocery.icon, equals('🛒'));
      expect(grocery.isDefault, isTrue);

      final incomeCategories = Category.getDefaultIncomeCategories();
      expect(incomeCategories.length, greaterThan(5));

      final salary = incomeCategories.firstWhere((c) => c.name.contains('Salary'));
      expect(salary.type, equals('income'));
      expect(salary.icon, equals('💰'));
    });

    test('should create user and group models', () {
      final user1 = User(
        name: 'John Doe',
        email: 'john@example.com',
        createdAt: DateTime.now(),
      );

      expect(user1.name, equals('John Doe'));
      expect(user1.email, equals('john@example.com'));

      final group = ExpenseGroup(
        name: 'Family',
        description: 'Family expenses',
        createdAt: DateTime.now(),
      );

      expect(group.name, equals('Family'));
      expect(group.description, equals('Family expenses'));
    });

    test('should create transaction model', () {
      final transaction = Transaction(
        amount: 100.0,
        date: DateTime.now(),
        accountId: 1,
        categoryId: 1,
        note: 'Test transaction',
        isShared: false,
        createdAt: DateTime.now(),
      );

      expect(transaction.amount, equals(100.0));
      expect(transaction.note, equals('Test transaction'));
      expect(transaction.isShared, isFalse);
      expect(transaction.groupId, isNull);

      final sharedTransaction = transaction.copyWith(
        isShared: true,
        groupId: 1,
      );

      expect(sharedTransaction.isShared, isTrue);
      expect(sharedTransaction.groupId, equals(1));
    });

    test('should create equal splits', () {
      final userIds = [1, 2, 3];
      final totalAmount = 300.0;

      final splits = Split.createEqualSplits(
        transactionId: 1,
        userIds: userIds,
        totalAmount: totalAmount,
      );

      expect(splits.length, equals(3));
      
      for (final split in splits) {
        expect(split.shareAmount, equals(100.0));
        expect(split.sharePercentage, closeTo(33.33, 0.1));
        expect(split.transactionId, equals(1));
      }
    });

    test('should create custom splits', () {
      final userShares = {1: 150.0, 2: 100.0, 3: 50.0};
      final totalAmount = 300.0;

      final splits = Split.createCustomSplits(
        transactionId: 1,
        userShares: userShares,
        totalAmount: totalAmount,
      );

      expect(splits.length, equals(3));

      final split1 = splits.firstWhere((s) => s.userId == 1);
      final split2 = splits.firstWhere((s) => s.userId == 2);
      final split3 = splits.firstWhere((s) => s.userId == 3);

      expect(split1.shareAmount, equals(150.0));
      expect(split1.sharePercentage, equals(50.0));

      expect(split2.shareAmount, equals(100.0));
      expect(split2.sharePercentage, closeTo(33.33, 0.1));

      expect(split3.shareAmount, equals(50.0));
      expect(split3.sharePercentage, closeTo(16.67, 0.1));
    });

    test('should create percentage splits', () {
      final userPercentages = {1: 60.0, 2: 25.0, 3: 15.0};
      final totalAmount = 200.0;

      final splits = Split.createPercentageSplits(
        transactionId: 1,
        userPercentages: userPercentages,
        totalAmount: totalAmount,
      );

      expect(splits.length, equals(3));

      final split1 = splits.firstWhere((s) => s.userId == 1);
      final split2 = splits.firstWhere((s) => s.userId == 2);
      final split3 = splits.firstWhere((s) => s.userId == 3);

      expect(split1.shareAmount, equals(120.0)); // 60% of 200
      expect(split1.sharePercentage, equals(60.0));

      expect(split2.shareAmount, equals(50.0)); // 25% of 200
      expect(split2.sharePercentage, equals(25.0));

      expect(split3.shareAmount, equals(30.0)); // 15% of 200
      expect(split3.sharePercentage, equals(15.0));
    });
  });
}