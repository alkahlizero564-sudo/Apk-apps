import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nawa/state/expense_provider.dart';
import 'package:nawa/widgets/summary_card.dart';
import 'package:nawa/widgets/transaction_tile.dart';
import 'package:nawa/widgets/empty_state_view.dart';
import 'package:nawa/screens/add_transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(provider.errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.loadTransactions(),
              child: const Text('إعادة المحاولة'),
            )
          ],
        ),
      );
    }

    final recentTransactions = provider.recentTransactions;

    return RefreshIndicator(
      onRefresh: () => provider.loadTransactions(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          SummaryCard(
            balance: provider.currentBalance,
            income: provider.totalIncome,
            expense: provider.totalExpense,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أحدث العمليات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (provider.transactions.isNotEmpty)
                Text(
                  '${provider.transactions.length} عملية',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentTransactions.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyStateView(
                title: 'لا توجد عمليات بعد',
                message: 'اضغط على زر (معاملة جديدة) لإضافة أول دخل أو مصروف لك.',
              ),
            )
          else
            ...recentTransactions.map((tx) {
              return TransactionTile(
                transaction: tx,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(itemToEdit: tx),
                    ),
                  );
                },
                onDelete: () {
                  provider.deleteTransaction(tx.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف المعاملة'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
