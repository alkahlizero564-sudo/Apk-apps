class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String categoryKey;
  final String? note;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.categoryKey,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'isExpense': isExpense,
        'categoryKey': categoryKey,
        'note': note,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      isExpense: json['isExpense'] as bool,
      categoryKey: json['categoryKey'] as String,
      note: json['note'] as String?,
    );
  }

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    bool? isExpense,
    String? categoryKey,
    String? note,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      categoryKey: categoryKey ?? this.categoryKey,
      note: note ?? this.note,
    );
  }
}
