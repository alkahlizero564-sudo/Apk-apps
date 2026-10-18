import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nawa/models/transaction_item.dart';
import 'package:nawa/state/expense_provider.dart';
import 'package:nawa/widgets/transaction_tile.dart';
import 'package:nawa/widgets/empty_state_view.dart';
import 'package:nawa/screens/add_transaction_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _searchQuery = '';
  TransactionType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    final filtered = provider.transactions.where((tx) {
      final matchesQuery = tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (tx.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesType = _typeFilter == null || tx.type == _typeFilter;
      return matchesQuery && matchesType;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'البحث عن معاملة أو ملاحظة...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('الكل'),
                selected: _typeFilter == null,
                onSelected: (_) => setState(() => _typeFilter = null),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('مصروفات'),
                selected: _typeFilter == TransactionType.expense,
                onSelected: (_) => setState(() => _typeFilter = TransactionType.expense),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('إيرادات'),
                selected: _typeFilter == TransactionType.income,
                onSelected: (_) => setState(() => _typeFilter = TransactionType.income),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyStateView(
                  title: 'لم يتم العثور على معاملات',
                  message: 'جرّب تعديل معايير البحث أو الفلتر أعلاه.',
                  icon: Icons.search_off,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
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
                            content: Text('تم حذف المعاملة بنجاح'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
