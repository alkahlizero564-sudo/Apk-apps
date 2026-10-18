import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class StorageService {
  static const String _expensesKey = 'awass_expenses';
  static const String _themeKey = 'awass_is_dark';

  Future<List<Expense>> loadExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_expensesKey);
      if (rawList == null || rawList.isEmpty) {
        return [];
      }
      return rawList.map((item) {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return Expense.fromJson(decoded);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = expenses.map((e) => jsonEncode(e.toJson())).toList();
    return prefs.setStringList(_expensesKey, stringList);
  }

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<bool> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_themeKey, isDark);
  }
}
