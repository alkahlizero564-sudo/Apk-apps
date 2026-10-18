import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/awas_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final AwasRepository _repository = AwasRepository();
  final Uuid _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = CategoryModel.defaultCategories;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDarkMode = false;
  String _searchQuery = '';
  TransactionType? _selectedTypeFilter;

  ExpenseProvider() {
    _init();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDarkMode => _isDarkMode;
  String get searchQuery => _searchQuery;
  TransactionType? get selectedTypeFilter => _selectedTypeFilter;
  List<CategoryModel> get categories => _categories;

  List<TransactionModel> get transactions => [..._transactions]
    ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> get filteredTransactions {
    return transactions.where((t) {
      final matchesSearch =
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesType =
          _selectedTypeFilter == null || t.type == _selectedTypeFilter;

      return matchesSearch && matchesType;
    }).toList();
  }

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (acc, t) => acc + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (acc, t) => acc + t.amount);

  double get netBalance => totalIncome - totalExpense;

  Map<String, double> get expensesByCategory {
    final Map<String, double> categorySums = {};
    for (var tx in _transactions.where((t) => t.type == TransactionType.expense)) {
      categorySums[tx.categoryId] =
          (categorySums[tx.categoryId] ?? 0.0) + tx.amount;
    }
    return categorySums;
  }

  CategoryModel getCategory(String categoryId) {
    return CategoryModel.getById(categoryId, _categories);
  }

  Future<void> _init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.ensureAuthenticated();
      _isDarkMode = await _repository.loadUserThemeMode();

      final fetchedCategories = await _repository.loadCategories();
      if (fetchedCategories.isNotEmpty) {
        _categories = fetchedCategories;
      }

      _transactions = await _repository.loadTransactions();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل البيانات من الخادم. يرجى التحقق من الاتصال.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _repository.saveUserThemeMode(_isDarkMode);
  }

  Future<bool> addTransaction({
    required String title,
    required double amount,
    required DateTime date,
    required String categoryId,
    required TransactionType type,
    String? note,
  }) async {
    try {
      final newTx = TransactionModel(
        id: _uuid.v4(),
        title: title,
        amount: amount,
        date: date,
        categoryId: categoryId,
        type: type,
        note: note,
      );

      final inserted = await _repository.addTransaction(newTx);
      _transactions.add(inserted);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إضافة المعاملة: ${e.toString().replaceAll('Exception: ', '')}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel updated) async {
    try {
      final saved = await _repository.updateTransaction(updated);
      final index = _transactions.indexWhere((t) => t.id == saved.id);
      if (index != -1) {
        _transactions[index] = saved;
      } else {
        _transactions.add(saved);
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل تعديل المعاملة: ${e.toString().replaceAll('Exception: ', '')}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف المعاملة: ${e.toString().replaceAll('Exception: ', '')}';
      notifyListeners();
      return false;
    }
  }

  Future<void> retry() async {
    await _init();
  }
}
