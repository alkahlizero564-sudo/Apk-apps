import 'package:flutter/material.dart';

enum TransactionType { expense, income }

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;
  final bool isSystem;
  final String? userId;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isSystem = false,
    this.userId,
  });

  static IconData _iconFromString(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'medical_services':
        return Icons.medical_services;
      case 'movie':
        return Icons.movie;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'laptop_mac':
        return Icons.laptop_mac;
      case 'trending_up':
        return Icons.trending_up;
      case 'category':
      default:
        return Icons.category;
    }
  }

  static String _iconToString(IconData icon) {
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.directions_car) return 'directions_car';
    if (icon == Icons.shopping_bag) return 'shopping_bag';
    if (icon == Icons.receipt_long) return 'receipt_long';
    if (icon == Icons.medical_services) return 'medical_services';
    if (icon == Icons.movie) return 'movie';
    if (icon == Icons.account_balance_wallet) return 'account_balance_wallet';
    if (icon == Icons.laptop_mac) return 'laptop_mac';
    if (icon == Icons.trending_up) return 'trending_up';
    return 'category';
  }

  static Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: _iconFromString(map['icon'] as String? ?? 'category'),
      color: _colorFromHex(map['color'] as String? ?? '#607D8B'),
      type: (map['type'] as String?) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      isSystem: map['is_system'] as bool? ?? false,
      userId: map['user_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': _iconToString(icon),
      'color': _colorToHex(color),
      'type': type.name,
      'is_system': isSystem,
      'user_id': userId,
    };
  }

  static final List<CategoryModel> defaultCategories = [
    const CategoryModel(
      id: 'food',
      name: 'طعام ومشروبات',
      icon: Icons.restaurant,
      color: Colors.orange,
      type: TransactionType.expense,
      isSystem: true,
    ),
    const CategoryModel(
      id: 'transport',
      name: 'مواصلات ونقل',
      icon: Icons.directions_car,
      color: Colors.blue,
      type: TransactionType.expense,
      isSystem: true,
    ),
    const CategoryModel(
      id: 'shopping',
      name: 'تسوق ومشتريات',
      icon: Icons.shopping_bag,
      color: Colors.purple,
      type: TransactionType.expense,
      isSystem: true,
    ),
    const CategoryModel(
      id: 'bills',
      name: 'فواتير والتزامات',
      icon: Icons.receipt_long,
      color: Colors.redAccent,
      type: TransactionType.expense,
      isSystem: true,
    ),
    const CategoryModel(
      id: 'health',
      name: 'صحة وعلاج',
      icon: Icons.medical_services,
      color: Colors.teal,
      type: TransactionType.expense,
      isSystem: true,
    ),
    const CategoryModel(
      id: 'entertainment',
      name: 'ترفيه وسفر',
      icon: Icons.movie,
      color: Colors.indigo,
      type: TransactionType.expense,
      isSystem: true,
    ),
    const CategoryModel(
      id: 'salary',
      name: 'راتب شهري',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      type: TransactionType.income,
      isSystem: true,
    ),
    const CategoryModel(
      id: 'freelance',
      name: 'عمل حر',
      icon: Icons.laptop_mac,
      color: Colors.cyan,
      type: TransactionType.income,
      isSystem: true,
    ),
    const CategoryModel(
      id: 'investment',
      name: 'استثمار وأرباح',
      icon: Icons.trending_up,
      color: Colors.amber,
      type: TransactionType.income,
      isSystem: true,
    ),
    const CategoryModel(
      id: 'other',
      name: 'أخرى',
      icon: Icons.category,
      color: Colors.blueGrey,
      type: TransactionType.expense,
      isSystem: true,
    ),
  ];

  static CategoryModel getById(String id, [List<CategoryModel>? dynamicCategories]) {
    if (dynamicCategories != null && dynamicCategories.isNotEmpty) {
      final found = dynamicCategories.where((cat) => cat.id == id);
      if (found.isNotEmpty) return found.first;
    }
    return defaultCategories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => defaultCategories.last,
    );
  }
}
