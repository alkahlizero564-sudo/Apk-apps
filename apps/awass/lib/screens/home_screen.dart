import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../state/expense_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/expense_card.dart';
import '../widgets/summary_header.dart';
import 'add_expense_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('أَوَاس'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded),
            tooltip: 'الإحصائيات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              provider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'تبديل المظهر',
            onPressed: () => provider.toggleTheme(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(provider.errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => provider.init(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SummaryHeader(),
                    ),
                    SliverToBoxAdapter(
                      child: _buildTimeFilters(context, provider),
                    ),
                    SliverToBoxAdapter(
                      child: _buildCategoryFilters(context, provider),
                    ),
                    if (provider.filteredExpenses.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final expense = provider.filteredExpenses[index];
                              return ExpenseCard(
                                expense: expense,
                                onDelete: () {
                                  provider.removeExpense(expense.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم حذف "${expense.title}"'),
                                      action: SnackBarAction(
                                        label: 'تراجع',
                                        onPressed: () {
                                          provider.addExpense(expense);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: provider.filteredExpenses.length,
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'مصروف جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTimeFilters(BuildContext context, ExpenseProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          CategoryFilterChip(
            label: 'كل الفترات',
            isSelected: provider.selectedFilter == TimeFilter.all,
            onTap: () => provider.setFilter(TimeFilter.all),
          ),
          CategoryFilterChip(
            label: 'هذا الشهر',
            isSelected: provider.selectedFilter == TimeFilter.thisMonth,
            onTap: () => provider.setFilter(TimeFilter.thisMonth),
          ),
          CategoryFilterChip(
            label: 'هذا الأسبوع',
            isSelected: provider.selectedFilter == TimeFilter.thisWeek,
            onTap: () => provider.setFilter(TimeFilter.thisWeek),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context, ExpenseProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          CategoryFilterChip(
            label: 'كل التصنيفات',
            isSelected: provider.selectedCategoryFilter == null,
            onTap: () => provider.setCategoryFilter(null),
          ),
          ...ExpenseCategory.all.map((c) {
            return CategoryFilterChip(
              label: c.arabicName,
              icon: c.icon,
              isSelected: provider.selectedCategoryFilter == c.type,
              onTap: () => provider.setCategoryFilter(
                provider.selectedCategoryFilter == c.type ? null : c.type,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مصروفات مسجلة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بتسجيل مصاريفك اليومية بالضغط على الزر أدناه لتتبع أسهل وأسرع لميزانيتك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
