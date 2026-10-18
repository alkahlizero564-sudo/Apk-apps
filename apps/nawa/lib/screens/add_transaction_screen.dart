import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:nawa/models/category_item.dart';
import 'package:nawa/models/transaction_item.dart';
import 'package:nawa/state/expense_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionItem? itemToEdit;

  const AddTransactionScreen({super.key, this.itemToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _selectedType;
  late String _selectedCategoryId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _titleController.text = item.title;
      _amountController.text = item.amount.toString();
      _noteController.text = item.note ?? '';
      _selectedType = item.type;
      _selectedCategoryId = item.categoryId;
      _selectedDate = item.date;
    } else {
      _selectedType = TransactionType.expense;
      _selectedCategoryId = CategoryItem.defaultExpenseCategories.first.id;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final provider = context.read<ExpenseProvider>();

    if (widget.itemToEdit != null) {
      final updated = widget.itemToEdit!.copyWith(
        title: _titleController.text.trim(),
        amount: parsedAmount,
        categoryId: _selectedCategoryId,
        type: _selectedType,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      await provider.updateTransaction(updated);
    } else {
      final newTx = TransactionItem(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        amount: parsedAmount,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        type: _selectedType,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      await provider.addTransaction(newTx);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    final categories = _selectedType == TransactionType.expense
        ? CategoryItem.defaultExpenseCategories
        : CategoryItem.defaultIncomeCategories;

    final dateFormatter = DateFormat('yyyy/MM/dd', 'ar');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل المعاملة' : 'إضافة معاملة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('مصروف'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('دخل'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    final list = _selectedType == TransactionType.expense
                        ? CategoryItem.defaultExpenseCategories
                        : CategoryItem.defaultIncomeCategories;
                    _selectedCategoryId = list.first.id;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان المعاملة *',
                  hintText: 'مثال: شراء بقالة، وقود، مكافأة...',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'الرجاء إدخال عنوان المعاملة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'المبلغ (ر.س) *',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'الرجاء إدخال المبلغ';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'الرجاء إدخال رقم صحيح وموجب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'الفئة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(cat.nameAr),
                    selected: isSelected,
                    selectedColor: cat.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedCategoryId = cat.id);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'التاريخ: ${dateFormatter.format(_selectedDate)}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_left),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة إضافية (اختياري)',
                  hintText: 'أي تفاصيل أخرى ترغب في تذكرها...',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة العملية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
