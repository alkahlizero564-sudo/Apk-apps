import 'package:flutter_test/flutter_test.dart';
import 'package:awass/models/category.dart';
import 'package:awass/models/expense.dart';
import 'package:awass/services/storage_service.dart';
import 'package:awass/state/expense_provider.dart';

class FakeStorageService extends StorageService {
  List<Expense> stored = [];
  bool isDark = false;

  @override
  Future<List<Expense>> loadExpenses() async => List.from(stored);

  @override
  Future<bool> saveExpenses(List<Expense> expenses) async {
    stored = List.from(expenses);
    return true;
  }

  @override
  Future<bool> loadDarkMode() async => isDark;

  @override
  Future<bool> saveDarkMode(bool val) async {
    isDark = val;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpenseProvider Tests', () {
    late FakeStorageService fakeStorage;
    late ExpenseProvider provider;

    setUp(() {
      fakeStorage = FakeStorageService();
      provider = ExpenseProvider(storageService: fakeStorage);
    });

    test('Initial state is empty and loads properly', () async {
      await provider.init();
      expect(provider.expenses, isEmpty);
      expect(provider.totalSpent, 0.0);
      expect(provider.isLoading, isFalse);
    });

    test('Adding and removing expense calculates total correctly', () async {
      await provider.init();

      final expense1 = Expense(
        id: '1',
        title: 'قهوة',
        amount: 15.0,
        date: DateTime.now(),
        categoryType: ExpenseCategoryType.food,
      );

      final expense2 = Expense(
        id: '2',
        title: 'وقود',
        amount: 85.0,
        date: DateTime.now(),
        categoryType: ExpenseCategoryType.transport,
      );

      await provider.addExpense(expense1);
      await provider.addExpense(expense2);

      expect(provider.expenses.length, 2);
      expect(provider.totalSpent, 100.0);
      expect(provider.categoryTotals[ExpenseCategoryType.food], 15.0);
      expect(provider.categoryTotals[ExpenseCategoryType.transport], 85.0);

      await provider.removeExpense('1');
      expect(provider.expenses.length, 1);
      expect(provider.totalSpent, 85.0);
    });

    test('Theme toggle updates dark mode status', () async {
      await provider.init();
      expect(provider.isDarkMode, isFalse);

      provider.toggleTheme();
      expect(provider.isDarkMode, isTrue);
    });
  });
}
