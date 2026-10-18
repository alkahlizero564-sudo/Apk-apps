import 'package:flutter/material.dart';

class CategoryMeta {
  final String key;
  final String nameAr;
  final IconData icon;
  final Color color;
  final bool isExpense;

  const CategoryMeta({
    required this.key,
    required this.nameAr,
    required this.icon,
    required this.color,
    required this.isExpense,
  });

  static const List<CategoryMeta> allCategories = [
    // Expenses
    CategoryMeta(
      key: 'food',
      nameAr: 'طعام ومشروبات',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF97316),
      isExpense: true,
    ),
    CategoryMeta(
      key: 'shopping',
      nameAr: 'تسوق ومشتريات',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFEC4899),
      isExpense: true,
    ),
    CategoryMeta(
      key: 'bills',
      nameAr: 'فواتير وسكن',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF3B82F6),
      isExpense: true,
    ),
    CategoryMeta(
      key: 'transport',
      nameAr: 'مواصلات وسيارة',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF6366F1),
      isExpense: true,
    ),
    CategoryMeta(
      key: 'health',
      nameAr: 'صحة وعلاج',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFEF4444),
      isExpense: true,
    ),
    CategoryMeta(
      key: 'entertainment',
      nameAr: 'ترفيه وخروجات',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFF8B5CF6),
      isExpense: true,
    ),
    CategoryMeta(
      key: 'other_expense',
      nameAr: 'مصروفات أخرى',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF64748B),
      isExpense: true,
    ),

    // Incomes
    CategoryMeta(
      key: 'salary',
      nameAr: 'راتب شهري',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF10B981),
      isExpense: false,
    ),
    CategoryMeta(
      key: 'freelance',
      nameAr: 'عمل حر وإضافي',
      icon: Icons.laptop_chromebook_rounded,
      color: Color(0xFF06B6D4),
      isExpense: false,
    ),
    CategoryMeta(
      key: 'investment',
      nameAr: 'أرباح واستثمار',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF14B8A6),
      isExpense: false,
    ),
    CategoryMeta(
      key: 'gift',
      nameAr: 'مكافآت وهدايا',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFF59E0B),
      isExpense: false,
    ),
    CategoryMeta(
      key: 'other_income',
      nameAr: 'دخل آخر',
      icon: Icons.attach_money_rounded,
      color: Color(0xFF059669),
      isExpense: false,
    ),
  ];

  static CategoryMeta getByKey(String key) {
    return allCategories.firstWhere(
      (element) => element.key == key,
      orElse: () => const CategoryMeta(
        key: 'unknown',
        nameAr: 'عام',
        icon: Icons.category_rounded,
        color: Color(0xFF64748B),
        isExpense: true,
      ),
    );
  }
}
