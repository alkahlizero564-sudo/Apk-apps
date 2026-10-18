import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';

class StorageService {
  static const _txKey = 'maher_transactions_key_v1';
  static const _themeKey = 'maher_dark_mode_key_v1';

  Future<List<TransactionItem>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_txKey);
    if (rawData == null || rawData.isEmpty) {
      return _generateInitialSampleData();
    }

    try {
      final List<dynamic> list = jsonDecode(rawData);
      return list
          .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_txKey, jsonString);
  }

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  List<TransactionItem> _generateInitialSampleData() {
    final now = DateTime.now();
    return [
      TransactionItem(
        id: 'tx_1',
        title: 'الراتب الشهري',
        amount: 8500,
        date: DateTime(now.year, now.month, 1),
        isExpense: false,
        categoryKey: 'salary',
        note: 'إيداع بنكي مباشر',
      ),
      TransactionItem(
        id: 'tx_2',
        title: 'شراء مقاضي السوبرماركت',
        amount: 430.50,
        date: DateTime(now.year, now.month, now.day - 1, 14, 20),
        isExpense: true,
        categoryKey: 'food',
        note: 'خضار وفواكه ومؤن منزلية',
      ),
      TransactionItem(
        id: 'tx_3',
        title: 'فاتورة الكهرباء والإنترنت',
        amount: 320.0,
        date: DateTime(now.year, now.month, now.day - 2, 10, 15),
        isExpense: true,
        categoryKey: 'bills',
      ),
      TransactionItem(
        id: 'tx_4',
        title: 'وقود السيارة',
        amount: 110.0,
        date: DateTime(now.year, now.month, now.day - 3, 19, 0),
        isExpense: true,
        categoryKey: 'transport',
      ),
      TransactionItem(
        id: 'tx_5',
        title: 'استشارة تصميم مستقل',
        amount: 1200.0,
        date: DateTime(now.year, now.month, now.day - 4, 16, 45),
        isExpense: false,
        categoryKey: 'freelance',
        note: 'دفعة مشروع متجر الكتروني',
      ),
    ];
  }
}
