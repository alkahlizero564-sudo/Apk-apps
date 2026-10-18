import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String nameAr;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.id,
    required this.nameAr,
    required this.icon,
    required this.color,
  });

  static const List<CategoryItem> defaultExpenseCategories = [
    CategoryItem(
      id: 'food',
      nameAr: 'طعام ومشروبات',
      icon: Icons.restaurant,
      color: Color(0xFFEF4444),
    ),
    CategoryItem(
      id: 'transport',
      nameAr: 'مواصلات ونقل',
      icon: Icons.directions_car,
      color: Color(0xFFF97316),
    ),
    CategoryItem(
      id: 'shopping',
      nameAr: 'تسوق ومشتريات',
      icon: Icons.shopping_bag,
      color: Color(0xFF8B5CF6),
    ),
    CategoryItem(
      id: 'bills',
      nameAr: 'فواتير والتزامات',
      icon: Icons.receipt_long,
      color: Color(0xFF06B6D4),
    ),
    CategoryItem(
      id: 'health',
      nameAr: 'صحة وعلاج',
      icon: Icons.medical_services,
      color: Color(0xFF10B981),
    ),
    CategoryItem(
      id: 'entertainment',
      nameAr: 'ترفيه وسفر',
      icon: Icons.movie_filter,
      color: Color(0xFFEC4899),
    ),
    CategoryItem(
      id: 'education',
      nameAr: 'تعليم وتطوير',
      icon: Icons.school,
      color: Color(0xFF3B82F6),
    ),
    CategoryItem(
      id: 'other_expense',
      nameAr: 'مصروفات أخرى',
      icon: Icons.category,
      color: Color(0xFF6B7280),
    ),
  ];

  static const List<CategoryItem> defaultIncomeCategories = [
    CategoryItem(
      id: 'salary',
      nameAr: 'راتب شهري',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF059669),
    ),
    CategoryItem(
      id: 'freelance',
      nameAr: 'عمل حر / إضافي',
      icon: Icons.laptop_mac,
      color: Color(0xFF10B981),
    ),
    CategoryItem(
      id: 'investment',
      nameAr: 'استثمار وأرباح',
      icon: Icons.trending_up,
      color: Color(0xFF2563EB),
    ),
    CategoryItem(
      id: 'gift',
      nameAr: 'مكافآت وهدايا',
      icon: Icons.card_giftcard,
      color: Color(0xFFD97706),
    ),
    CategoryItem(
      id: 'other_income',
      nameAr: 'دخل آخر',
      icon: Icons.attach_money,
      color: Color(0xFF4B5563),
    ),
  ];

  static CategoryItem getById(String id) {
    final all = [...defaultExpenseCategories, ...defaultIncomeCategories];
    return all.firstWhere(
      (cat) => cat.id == id,
      orElse: () => const CategoryItem(
        id: 'unknown',
        nameAr: 'عام',
        icon: Icons.money,
        color: Colors.grey,
      ),
    );
  }
}
