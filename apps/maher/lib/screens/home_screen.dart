import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/expense_provider.dart';
import '../state/theme_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProv = context.watch<ExpenseProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'تطبيق ماهر',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'الإحصائيات والتحليلات',
            icon: const Icon(Icons.pie_chart_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: themeProv.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
            icon: Icon(
              themeProv.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => themeProv.toggleTheme(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: expenseProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenseProv.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text(
                        expenseProv.errorMessage!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => expenseProv.loadData(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => expenseProv.loadData(),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SummaryCard(
                                balance: expenseProv.balance,
                                income: expenseProv.totalIncome,
                                expense: expenseProv.totalExpense,
                              ),
                              const SizedBox(height: 18),
                              _buildFilterBar(context, expenseProv),
                              const SizedBox(height: 14),
                              _buildSearchBar(context, expenseProv),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'العمليات (${expenseProv.filteredTransactions.length})',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (expenseProv.searchQuery.isNotEmpty ||
                                      expenseProv.selectedCategoryFilter !=
                                          null)
                                    TextButton(
                                      onPressed: () {
                                        expenseProv.setSearchQuery('');
                                        expenseProv.setCategoryFilter(null);
                                      },
                                      child: const Text('إعادة التعيين'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (expenseProv.filteredTransactions.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 64,
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'لا توجد عمليات مسجلة',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'اضغط على زر (+) في الأسفل لإضافة دخل أو مصروف جديد بسهولة.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.colorScheme.outline,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final tx =
                                    expenseProv.filteredTransactions[index];
                                return TransactionTile(
                                  item: tx,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(
                                          itemToEdit: tx,
                                        ),
                                      ),
                                    );
                                  },
                                  onDelete: () {
                                    expenseProv.deleteTransaction(tx.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم حذف "${tx.title}"'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                );
                              },
                              childCount:
                                  expenseProv.filteredTransactions.length,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'إضافة معاملة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, ExpenseProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'الشهر الحالي',
            isSelected: provider.activeFilter == DateFilter.thisMonth,
            onSelected: () => provider.setFilter(DateFilter.thisMonth),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'هذا الأسبوع',
            isSelected: provider.activeFilter == DateFilter.thisWeek,
            onSelected: () => provider.setFilter(DateFilter.thisWeek),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'اليوم',
            isSelected: provider.activeFilter == DateFilter.today,
            onSelected: () => provider.setFilter(DateFilter.today),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'كل الأوقات',
            isSelected: provider.activeFilter == DateFilter.all,
            onSelected: () => provider.setFilter(DateFilter.all),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ExpenseProvider provider) {
    final theme = Theme.of(context);
    return TextField(
      onChanged: (val) => provider.setSearchQuery(val),
      decoration: InputDecoration(
        hintText: 'ابحث في المصروفات أو الملاحظات...',
        hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: theme.cardTheme.color,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
