import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../state/expense_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? initialTransaction;

  const AddTransactionScreen({super.key, this.initialTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late TransactionType _selectedType;
  late String _selectedCategoryId;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.initialTransaction;

    _titleController = TextEditingController(text: edit?.title ?? '');
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: edit?.note ?? '');
    _selectedType = edit?.type ?? TransactionType.expense;
    _selectedDate = edit?.date ?? DateTime.now();

    final provider = context.read<ExpenseProvider>();
    final available = provider.categories
        .where((c) => c.type == _selectedType)
        .toList();
    _selectedCategoryId = edit?.categoryId ?? (available.isNotEmpty ? available.first.id : 'food');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      final provider = context.read<ExpenseProvider>();
      final cats = provider.categories.where((c) => c.type == type).toList();
      if (cats.isNotEmpty) {
        _selectedCategoryId = cats.first.id;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<ExpenseProvider>();

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    bool success = false;
    if (widget.initialTransaction == null) {
      success = await provider.addTransaction(
        title: title,
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        type: _selectedType,
        note: note,
      );
    } else {
      final updated = widget.initialTransaction!.copyWith(
        title: title,
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        type: _selectedType,
        note: note,
      );
      success = await provider.updateTransaction(updated);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialTransaction == null
                  ? 'تمت إضافة المعاملة بنجاح'
                  : 'تم تحديث المعاملة بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'حدث خطأ أثناء حفظ المعاملة.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTransaction != null;
    final provider = context.watch<ExpenseProvider>();
    final availableCategories = provider.categories
        .where((c) => c.type == _selectedType)
        .toList();

    if (!availableCategories.any((cat) => cat.id == _selectedCategoryId) &&
        availableCategories.isNotEmpty) {
      _selectedCategoryId = availableCategories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل المعاملة' : 'معاملة جديدة'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  onSelectionChanged: (newSelection) {
                    _onTypeChanged(newSelection.first);
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'العنوان أو الوصف المختصر',
                    hintText: 'مثال: وجبة غداء، فاتورة كهرباء...',
                    prefixIcon: const Icon(Icons.edit_note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال عنوان المعاملة';
                    }
                    if (value.trim().length < 2) {
                      return 'العنوان يجب ألا يقل عن حرفين';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'المبلغ (ر.س)',
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال المبلغ';
                    }
                    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'يرجى إدخال مبلغ صحيح أكبر من الصفر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                if (availableCategories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'التصنيف',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: availableCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(cat.icon, color: cat.color, size: 20),
                            const SizedBox(width: 10),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategoryId = val);
                      }
                    },
                  ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تاريخ المعاملة',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy', 'ar_SA').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'ملاحظة إضافية (اختياري)',
                    hintText: 'أي تفاصيل أخرى ترغب في تدوينها...',
                    prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    isEditing ? 'تحديث المعاملة' : 'حفظ المعاملة',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
