import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nawa/state/expense_provider.dart';
import 'package:nawa/models/category_item.dart';
import 'package:nawa/widgets/empty_state_view.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenseMap = provider.getCategoryExpenseTotals();
    final totalExpense = provider.totalExpense;
    final formatter = NumberFormat('#,##0.00', 'ar');

    if (totalExpense == 0) {
      return const EmptyStateView(
        title: 'لا توجد إحصائيات كافية',
        message: 'أضف بعض المصروفات لعرض التحليل البياني والتوزيع المالي.',
        icon: Icons.analytics_outlined,
      );
    }

    final sortedEntries = expenseMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'توزيع المصروفات حسب الفئة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'المجموع الكلي: ${formatter.format(totalExpense)} ر.س',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: sortedEntries.map((e) {
                        final cat = CategoryItem.getById(e.key);
                        final fraction = totalExpense > 0 ? e.value / totalExpense : 0.0;
                        return Expanded(
                          flex: (fraction * 1000).toInt().clamp(1, 1000),
                          child: Container(color: cat.color),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'تفاصيل الفئات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...sortedEntries.map((entry) {
          final cat = CategoryItem.getById(entry.key);
          final percent = (entry.value / totalExpense) * 100;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.nameAr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${formatter.format(entry.value)} ر.س',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: cat.color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
