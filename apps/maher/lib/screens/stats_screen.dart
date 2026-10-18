import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/expense_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProv = context.watch<ExpenseProvider>();
    final breakdown = expenseProv.expenseBreakdown;
    final total = expenseProv.totalExpense;
    final currencyFormat = NumberFormat('#,##0.00', 'ar');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تحليل المصروفات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: breakdown.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد بيانات مصروفات لتحليلها',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'عند تسجيل مصروفات في الفترة المحددة، ستظهر هنا نسب وتوزيع الإنفاق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    border: Border.all(
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'إجمالي المصروفات للفترة المحددة',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${currencyFormat.format(total)} ر.س',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'توزيع الإنفاق حسب التصنيف',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...breakdown.map((item) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: item.category.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.category.icon,
                                  color: item.category.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.category.nameAr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${currencyFormat.format(item.totalAmount)} ر.س',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${item.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: item.percentage / 100,
                              minHeight: 8,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                item.category.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
