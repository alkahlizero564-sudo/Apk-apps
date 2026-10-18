import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';

enum TimeFilter { all, thisMonth, thisWeek }

class ExpenseProvider extends ChangeNotifier {
  final StorageService _storageService;

  ExpenseProvider({StorageService? storageService})
      : _storageService = storageService ?? StorageService() {
    init();
  }

  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDarkMode = false;
  TimeFilter _selectedFilter = TimeFilter.all;
  ExpenseCategoryType? _selectedCategoryFilter;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDarkMode => _isDarkMode;
  TimeFilter get selectedFilter => _selectedFilter;
  ExpenseCategoryType? get selectedCategoryFilter => _selectedCategoryFilter;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isDarkMode = await _storageService.loadDarkMode();
      _expenses = await _storageService.loadExpenses();
      _sortExpenses();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل البيانات';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _storageService.saveDarkMode(_isDarkMode);
  }

  void setFilter(TimeFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(ExpenseCategoryType? categoryType) {
    _selectedCategoryFilter = categoryType;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    _sortExpenses();
    notifyListeners();
    await _storageService.saveExpenses(_expenses);
  }

  Future<void> removeExpense(String id) async {
    _expenses.removeWhere((item) => item.id == id);
    notifyListeners();
    await _storageService.saveExpenses(_expenses);
  }

  void _sortExpenses() {
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> get filteredExpenses {
    final now = DateTime.now();

    return _expenses.where((expense) {
      // Category check
      if (_selectedCategoryFilter != null &&
          expense.categoryType != _selectedCategoryFilter) {
        return false;
      }

      // Time check
      switch (_selectedFilter) {
        case TimeFilter.all:
          return true;
        case TimeFilter.thisMonth:
          return expense.date.year == now.year &&
              expense.date.month == now.month;
        case TimeFilter.thisWeek:
          final difference = now.difference(expense.date).inDays;
          return difference >= 0 && difference < 7;
      }
    }).toList();
  }

  double get totalSpent {
    return filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get currentMonthSpent {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get todaySpent {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<ExpenseCategoryType, double> get categoryTotals {
    final map = <ExpenseCategoryType, double>{};
    for (final exp in filteredExpenses) {
      map[exp.categoryType] = (map[exp.categoryType] ?? 0.0) + exp.amount;
    }
    return map;
  }
}
