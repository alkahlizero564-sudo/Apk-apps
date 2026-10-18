import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_item.dart';
import '../models/category_meta.dart';
import '../state/expense_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionItem? itemToEdit;

  const AddTransactionScreen({super.key, this.itemToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _isExpense;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategoryKey;

  @override
  void initState() {
    super.initState();
    final edit = widget.itemToEdit;
    _isExpense = edit?.isExpense ?? true;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _amountController =
        TextEditingController(text: edit != null ? edit.amount.toString() : '');
    _noteController = TextEditingController(text: edit?.note ?? '');
    _selectedDate = edit?.date ?? DateTime.now();

    if (edit != null) {
      _selectedCategoryKey = edit.categoryKey;
    } else {
      _selectedCategoryKey = _isExpense ? 'food' : 'salary';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _switchType(bool isExpense) {
    if (_isExpense == isExpense) return;
    setState(() {
      _isExpense = isExpense;
      _selectedCategoryKey = _isExpense ? 'food' : 'salary';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      final timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      setState(() {
        if (timePicked != null) {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح أكبر من الصفر')),
      );
      return;
    }

    final provider = context.read<ExpenseProvider>();

    if (widget.itemToEdit != null) {
      final updated = widget.itemToEdit!.copyWith(
        title: _titleController.text.trim(),
        amount: parsedAmount,
        date: _selectedDate,
        isExpense: _isExpense,
        categoryKey: _selectedCategoryKey,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      provider.updateTransaction(updated);
    } else {
      final newTx = TransactionItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: parsedAmount,
        date: _selectedDate,
        isExpense: _isExpense,
        categoryKey: _selectedCategoryKey,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      provider.addTransaction(newTx);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = CategoryMeta.allCategories
        .where((cat) => cat.isExpense == _isExpense)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemToEdit != null ? 'تعديل المعاملة' : 'إضافة معاملة جديدة',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Segmented toggle: Expense vs Income
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchType(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isExpense ? Colors.red.shade600 : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'مصروف',
                          style: TextStyle(
                            color: _isExpense ? Colors.white : theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchType(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isExpense ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'دخل',
                          style: TextStyle(
                            color: !_isExpense ? Colors.white : theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount field
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.00',
                suffixText: 'ر.س',
                suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                labelText: 'المبلغ',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى إدخال المبلغ';
                }
                final num = double.tryParse(val.trim());
                if (num == null || num <= 0) {
                  return 'أدخل رقماً صحيحاً موجباً';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'الوصف أو البند',
                hintText: 'مثال: وجبة عشاء، صيانة سيارة، فاتورة هاتف',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى كتابة عنوان المعاملة';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category Selection
            const Text(
              'التصنيف',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = cat.key == _selectedCategoryKey;
                return ChoiceChip(
                  avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                  label: Text(cat.nameAr),
                  selected: isSelected,
                  selectedColor: cat.color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedCategoryKey = cat.key);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Date selector
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              leading: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
              title: const Text('التاريخ والوقت', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظات إضافية (اختياري)',
                hintText: 'أية تفاصيل إضافية تريد تذكرها...',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 30),

            // Save button
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saveForm,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  widget.itemToEdit != null ? 'تحديث المعاملة' : 'حفظ المعاملة',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
