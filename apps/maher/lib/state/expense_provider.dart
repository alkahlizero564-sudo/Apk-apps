import 'package:flutter/foundation.dart';
import '../models/transaction_item.dart';
import '../models/category_meta.dart';
import '../services/storage_service.dart';

enum DateFilter { all, today, thisWeek, thisMonth }

class CategoryBreakdown {
  final CategoryMeta category;
  final double totalAmount;
  final double percentage;

  const CategoryBreakdown({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });
}

class ExpenseProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<TransactionItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  DateFilter _activeFilter = DateFilter.thisMonth;
  String _searchQuery = '';
  String? _selectedCategoryFilter;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryFilter => _selectedCategoryFilter;

  List<TransactionItem> get allTransactions => List.unmodifiable(_items);

  List<TransactionItem> get filteredTransactions {
    final now = DateTime.now();

    return _items.where((item) {
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesNote = item.note?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesNote) return false;
      }

      if (_selectedCategoryFilter != null &&
          item.categoryKey != _selectedCategoryFilter) {
        return false;
      }

      switch (_activeFilter) {
        case DateFilter.all:
          return true;
        case DateFilter.today:
          return item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day;
        case DateFilter.thisWeek:
          final diffDays = now.difference(item.date).inDays;
          return diffDays >= 0 && diffDays <= 7;
        case DateFilter.thisMonth:
          return item.date.year == now.year && item.date.month == now.month;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalIncome {
    return filteredTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return filteredTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  List<CategoryBreakdown> get expenseBreakdown {
    final expenses = filteredTransactions.where((t) => t.isExpense).toList();
    final double total = totalExpense;

    if (total == 0) return [];

    final Map<String, double> categoryMap = {};
    for (final tx in expenses) {
      categoryMap[tx.categoryKey] = (categoryMap[tx.categoryKey] ?? 0) + tx.amount;
    }

    final List<CategoryBreakdown> list = [];
    categoryMap.forEach((catKey, amount) {
      list.add(CategoryBreakdown(
        category: CategoryMeta.getByKey(catKey),
        totalAmount: amount,
        percentage: (amount / total) * 100,
      ));
    });

    list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return list;
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _storageService.loadTransactions();
      _items.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل البيانات';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(TransactionItem item) async {
    _items.insert(0, item);
    notifyListeners();
    await _storageService.saveTransactions(_items);
  }

  Future<void> updateTransaction(TransactionItem item) async {
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
      await _storageService.saveTransactions(_items);
    }
  }

  Future<void> deleteTransaction(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    await _storageService.saveTransactions(_items);
  }

  void setFilter(DateFilter filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? key) {
    _selectedCategoryFilter = key;
    notifyListeners();
  }
}
