import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class AwasRepository {
  final SupabaseClient _client;

  AwasRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> ensureAuthenticated() async {
    if (_client.auth.currentUser == null) {
      try {
        await _client.auth.signInAnonymously();
      } catch (e) {
        debugPrint('Anonymous auth error: $e');
      }
    }
  }

  Future<bool> loadUserThemeMode() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final res = await _client
          .from('awas_user_profiles')
          .select('is_dark_mode')
          .eq('id', user.id)
          .maybeSingle();

      if (res != null && res['is_dark_mode'] != null) {
        return res['is_dark_mode'] as bool;
      }
      return false;
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
      return false;
    }
  }

  Future<void> saveUserThemeMode(bool isDarkMode) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('awas_user_profiles').upsert({
        'id': user.id,
        'is_dark_mode': isDarkMode,
      });
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<List<CategoryModel>> loadCategories() async {
    try {
      final res = await _client
          .from('awas_categories')
          .select()
          .order('name', ascending: true);

      final list = (res as List)
          .map((data) => CategoryModel.fromMap(data as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        return CategoryModel.defaultCategories;
      }
      return list;
    } catch (e) {
      debugPrint('Error loading categories from Supabase: $e');
      return CategoryModel.defaultCategories;
    }
  }

  Future<List<TransactionModel>> loadTransactions() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final res = await _client
          .from('awas_transactions')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false);

      return (res as List)
          .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      throw Exception('تعذر جلب المعاملات من الخادم. يرجى التحقق من الاتصال.');
    }
  }

  Future<TransactionModel> addTransaction(TransactionModel tx) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً لإضافة معاملة.');
    }

    try {
      final payload = tx.toMap();
      payload['user_id'] = user.id;

      final res = await _client
          .from('awas_transactions')
          .insert(payload)
          .select()
          .single();

      return TransactionModel.fromMap(res);
    } catch (e) {
      debugPrint('Error inserting transaction: $e');
      throw Exception('فشل في حفظ المعاملة في الخادم.');
    }
  }

  Future<TransactionModel> updateTransaction(TransactionModel tx) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('غير مصرح بهذا التعديل.');
    }

    try {
      final payload = tx.toMap();
      payload.remove('user_id');

      final res = await _client
          .from('awas_transactions')
          .update(payload)
          .eq('id', tx.id)
          .eq('user_id', user.id)
          .select()
          .single();

      return TransactionModel.fromMap(res);
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      throw Exception('فشل في تحديث بيانات المعاملة.');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('غير مصرح بهذا الحذف.');
    }

    try {
      await _client
          .from('awas_transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      throw Exception('فشل في حذف المعاملة من الخادم.');
    }
  }
}
