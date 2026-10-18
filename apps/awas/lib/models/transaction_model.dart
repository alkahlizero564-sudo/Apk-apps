import 'category_model.dart';

class TransactionModel {
  final String id;
  final String? userId;
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final TransactionType type;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransactionModel({
    required this.id,
    this.userId,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.type,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'type': type.name,
      'note': note,
    };
    if (userId != null) {
      map['user_id'] = userId;
    }
    return map;
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as String,
      type: TransactionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      note: map['note'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    DateTime? date,
    String? categoryId,
    TransactionType? type,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
