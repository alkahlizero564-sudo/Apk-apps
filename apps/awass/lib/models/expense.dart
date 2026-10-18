import 'category.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategoryType categoryType;
  final String? note;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryType,
    this.note,
  });

  ExpenseCategory get category => ExpenseCategory.fromType(categoryType);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryType': categoryType.name,
      'note': note,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      categoryType: ExpenseCategoryType.values.firstWhere(
        (e) => e.name == json['categoryType'],
        orElse: () => ExpenseCategoryType.other,
      ),
      note: json['note'] as String?,
    );
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    ExpenseCategoryType? categoryType,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryType: categoryType ?? this.categoryType,
      note: note ?? this.note,
    );
  }
}
