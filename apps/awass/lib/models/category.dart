import 'package:flutter/material.dart';

enum ExpenseCategoryType {
  food,
  transport,
  shopping,
  bills,
  health,
  entertainment,
  education,
  other,
}

class ExpenseCategory {
  final ExpenseCategoryType type;
  final String arabicName;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.type,
    required this.arabicName,
    required this.icon,
    required this.color,
  });

  static const List<ExpenseCategory> all = [
    ExpenseCategory(
      type: ExpenseCategoryType.food,
      arabicName: 'طعام ومشروبات',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE65100),
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.transport,
      arabicName: 'مواصلات ونقل',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF0288D1),
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.shopping,
      arabicName: 'تسوق ومشتريات',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF7B1FA2),
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.bills,
      arabicName: 'فواتير والتزامات',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFC2185B),
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.health,
      arabicName: 'صحة وعلاج',
      icon: Icons.favorite_rounded,
      color: Color(0xFFD32F2F),
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.entertainment,
      arabicName: 'ترفيه ورحلات',
      icon: Icons.movie_filter_rounded,
      color: Color(0xFFF57C00),
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.education,
      arabicName: 'تعليم وتطوير',
      icon: Icons.school_rounded,
      color: Color(0xFF00796B),
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.other,
      arabicName: 'نفقات أخرى',
      icon: Icons.category_rounded,
      color: Color(0xFF546E7A),
    ),
  ];

  static ExpenseCategory fromType(ExpenseCategoryType type) {
    return all.firstWhere(
      (c) => c.type == type,
      orElse: () => all.last,
    );
  }

  static ExpenseCategory fromName(String name) {
    return all.firstWhere(
      (c) => c.type.name == name,
      orElse: () => all.last,
    );
  }
}
