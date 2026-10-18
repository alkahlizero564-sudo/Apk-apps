import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nawa/models/transaction_item.dart';

class StorageService {
  static const String _transactionsKey = 'nawa_transactions';
  static const String _themeModeKey = 'nawa_theme_mode';

  Future<List<TransactionItem>> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_transactionsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => TransactionItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveTransactions(List<TransactionItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappedList = items.map((item) => item.toMap()).toList();
      final jsonString = json.encode(mappedList);
      return await prefs.setString(_transactionsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themeModeKey);
      if (modeString == null) return ThemeMode.system;
      return ThemeMode.values.firstWhere(
        (e) => e.name == modeString,
        orElse: () => ThemeMode.system,
      );
    } catch (e) {
      return ThemeMode.system;
    }
  }

  Future<bool> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_themeModeKey, mode.name);
    } catch (e) {
      return false;
    }
  }
}
