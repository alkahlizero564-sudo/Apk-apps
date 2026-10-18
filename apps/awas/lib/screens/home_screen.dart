import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../state/expense_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'عوّاس - المصروفات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'الإحصائيات',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: provider.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
            icon: Icon(
              provider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => provider.toggleTheme(),
          ),
        ],
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
        icon: const Icon(Icons.add),
        label: const Text('إضافة معاملة'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? _buildErrorView(context, provider)
              : RefreshIndicator(
                  onRefresh: () => provider.retry(),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SummaryCard(
                                balance: provider.netBalance,
                                income: provider.totalIncome,
                                expense: provider.totalExpense,
                              ),
                              const SizedBox(height: 16),
                              _buildSearchBar(context, provider),
                              const SizedBox(height: 12),
                              _buildFilterChips(context, provider),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      provider.filteredTransactions.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyView(context),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, index) {
                                    final tx = provider.filteredTransactions[index];
                                    return TransactionItem(
                                      transaction: tx,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddTransactionScreen(
                                              initialTransaction: tx,
                                            ),
                                          ),
                                        );
                                      },
                                      onDelete: () => provider.deleteTransaction(tx.id),
                                    );
                                  },
                                  childCount: provider.filteredTransactions.length,
                                ),
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ExpenseProvider provider) {
    return TextField(
      onChanged: provider.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'ابحث في العنوان أو الملاحظات...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, ExpenseProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('الكل'),
            selected: provider.selectedTypeFilter == null,
            onSelected: (_) => provider.setTypeFilter(null),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('المصروفات فقط'),
            selected: provider.selectedTypeFilter == TransactionType.expense,
            onSelected: (_) => provider.setTypeFilter(TransactionType.expense),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('الدخل فقط'),
            selected: provider.selectedTypeFilter == TransactionType.income,
            onSelected: (_) => provider.setTypeFilter(TransactionType.income),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, ExpenseProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 54, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'حدث خطأ غير متوقع',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => provider.retry(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'لا توجد معاملات مسجلة بعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر إضافة معاملة لتسجيل مصاريفك ودخلك بكل سهولة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
