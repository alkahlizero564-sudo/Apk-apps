import 'package:flutter/material.dart';
import 'package:nawa/models/transaction_item.dart';
import 'package:nawa/services/storage_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final StorageService _storageService;

  List<TransactionItem> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  ExpenseProvider(this._storageService);

  List<TransactionItem> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get currentBalance => totalIncome - totalExpense;

  List<TransactionItem> get recentTransactions {
    final list = List<TransactionItem>.from(_transactions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.take(5).toList();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _storageService.loadTransactions();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل البيانات';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction(TransactionItem item) async {
    try {
      _transactions.insert(0, item);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      return await _storageService.saveTransactions(_transactions);
    } catch (e) {
      _errorMessage = 'فشل في حفظ المعاملة الجديدة';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return await _storageService.saveTransactions(_transactions);
    } catch (e) {
      _errorMessage = 'فشل في حذف المعاملة';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionItem updated) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _transactions[index] = updated;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
        return await _storageService.saveTransactions(_transactions);
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل في تحديث المعاملة';
      notifyListeners();
      return false;
    }
  }

  Map<String, double> getCategoryExpenseTotals() {
    final Map<String, double> totals = {};
    for (final item in _transactions) {
      if (item.type == TransactionType.expense) {
        totals[item.categoryId] = (totals[item.categoryId] ?? 0.0) + item.amount;
      }
    }
    return totals;
  }
}
