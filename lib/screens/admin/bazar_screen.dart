import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class BazarScreen extends StatefulWidget {
  const BazarScreen({super.key});

  @override
  State<BazarScreen> createState() => _BazarScreenState();
}

class _BazarScreenState extends State<BazarScreen> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final expenses = data.monthExpenses;
    final summary = data.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('বাজার খরচ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addExpense,
          ),
        ],
      ),
      body: data.isLoading && expenses.isEmpty
          ? const LoadingView()
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('মাসের মোট খরচ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        AppUtils.formatTaka(summary?.totalExpense ?? 0),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: dangerColor),
                      ),
                    ],
                  ),
                ),
                if (expenses.isEmpty)
                  const Expanded(child: EmptyState(message: 'এই মাসে কোনো খরচ নেই'))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, i) {
                        final e = expenses[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _catColor(e.category),
                              child: Text(
                                e.category.isEmpty
                                    ? '?'
                                    : e.category.substring(0, 1),
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(
                              '${e.category}  ${AppUtils.formatTaka(e.amount)}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${AppUtils.formatDate(e.date)}${e.description.isNotEmpty ? ' • ${e.description}' : ''}${e.note.isNotEmpty ? '\n${e.note}' : ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _editExpense(e);
                                if (v == 'delete') _deleteExpense(e);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('সম্পাদনা')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('মুছুন')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Color _catColor(String cat) {
    const colors = {
      'Rice': primaryColor,
      'Fish': Colors.blue,
      'Meat': Colors.brown,
      'Vegetable': Colors.green,
      'Dal': Colors.orange,
      'Oil': Colors.amber,
      'Salt': Colors.grey,
      'Grocery': Colors.teal,
      'Gas': Colors.indigo,
      'Water': Colors.lightBlue,
      'Other': Colors.deepPurple,
    };
    return colors[cat] ?? textSecondary;
  }

  Future<void> _addExpense() async {
    final data = context.read<DataProvider>();
    final paidByOptions = [
      ...data.activeMembers.map((m) => m.name),
      'Admin',
    ];
    await showDialog(
      context: context,
      builder: (_) => ExpenseFormDialog(
        paidByOptions: paidByOptions,
        onSubmit: (date, category, description, amount, paidBy, note) async {
          await data.addExpense(
            date: date,
            category: category,
            description: description,
            amount: amount,
            paidBy: paidBy,
            note: note,
          );
          if (mounted) ConfirmDialog.showToast(context, 'খরচ যোগ হয়েছে');
        },
      ),
    );
  }

  Future<void> _editExpense(Expense e) async {
    final data = context.read<DataProvider>();
    final paidByOptions = [
      ...data.activeMembers.map((m) => m.name),
      'Admin',
    ];
    await showDialog(
      context: context,
      builder: (_) => ExpenseFormDialog(
        existing: e,
        paidByOptions: paidByOptions,
        onSubmit: (date, category, description, amount, paidBy, note) async {
          final updated = e.copyWith(
            date: date,
            category: category,
            description: description,
            amount: amount,
            paidBy: paidBy,
            note: note,
          );
          await data.updateExpense(updated);
          if (mounted) ConfirmDialog.showToast(context, 'খরচ আপডেট হয়েছে');
        },
      ),
    );
  }

  Future<void> _deleteExpense(Expense e) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'খরচ মুছুন',
      message: '${e.category} - ${AppUtils.formatTaka(e.amount)} মুছে ফেলবেন?\n'
          'ইতিহাস থেকে মুছে যাবে।',
      confirmText: 'মুছুন',
      destructive: true,
    );
    if (ok) {
      final data = context.read<DataProvider>();
      await data.deleteExpense(e.id);
      if (mounted) ConfirmDialog.showToast(context, 'খরচ মুছে ফেলা হয়েছে');
    }
  }
}

class ExpenseFormDialog extends StatefulWidget {
  final Expense? existing;
  final List<String> paidByOptions;
  final Future<void> Function(DateTime, String, String, double, String, String)
      onSubmit;

  const ExpenseFormDialog({
    super.key,
    this.existing,
    required this.paidByOptions,
    required this.onSubmit,
  });

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  late final TextEditingController _amountCtrl;
  final _descriptionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late DateTime _date;
  late String _category;
  late String _paidBy;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? DateTime.now();
    _category = widget.existing?.category ?? 'Rice';
    _paidBy = widget.existing?.paidBy ??
        (widget.paidByOptions.isNotEmpty ? widget.paidByOptions.first : 'Admin');
    _amountCtrl = TextEditingController(
        text: widget.existing != null
            ? '${widget.existing!.amount}'
            : '');
    _descriptionCtrl.text = widget.existing?.description ?? '';
    _noteCtrl.text = widget.existing?.note ?? '';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'নতুন খরচ' : 'খরচ সম্পাদনা'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'তারিখ',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(AppUtils.formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'বিভাগ'),
              items: AppConstants.expenseCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Rice'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'পরিমাণ (৳) *',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                  labelText: 'বিবরণ', prefixIcon: Icon(Icons.notes)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paidBy,
              decoration: const InputDecoration(labelText: 'পরিশোধ করেছেন'),
              items: widget.paidByOptions
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _paidBy = v ?? 'Admin'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'নোট (ঐচ্ছিক)', prefixIcon: Icon(Icons.sticky_note_2_outlined)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('বাতিল'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: Text(_loading ? 'সেভ হচ্ছে...' : 'সেভ করুন'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ConfirmDialog.showToast(context, 'সঠিক পরিমাণ দিন');
      return;
    }
    setState(() => _loading = true);
    await widget.onSubmit(
        _date, _category, _descriptionCtrl.text.trim(), amount, _paidBy,
        _noteCtrl.text.trim());
    if (mounted) {
      Navigator.pop(context);
    }
  }
}