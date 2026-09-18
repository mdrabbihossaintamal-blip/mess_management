import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/payment.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final payments = data.monthPayments;
    final summary = data.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('সদস্য জমা'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPayment,
          ),
        ],
      ),
      body: data.isLoading && payments.isEmpty
          ? const LoadingView()
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('মোট সংগ্রহ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        AppUtils.formatTaka(summary?.totalCollection ?? 0),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.green),
                      ),
                    ],
                  ),
                ),
                if (payments.isEmpty)
                  const Expanded(child: EmptyState(message: 'এই মাসে কোনো পেমেন্ট নেই'))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, i) {
                        final p = payments[i];
                        final member = data.memberById(p.memberId);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.payments, color: Colors.white),
                            ),
                            title: Text(
                              '${member?.name ?? 'সদস্য'} — ${AppUtils.formatTaka(p.amount)}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${AppUtils.formatDate(p.date)} • ${p.paymentMethod}'
                              '${p.note.isNotEmpty ? ' • ${p.note}' : ''}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _editPayment(p);
                                if (v == 'delete') _deletePayment(p);
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

  Future<void> _addPayment() async {
    final data = context.read<DataProvider>();
    final members = data.activeMembers;
    if (members.isEmpty) {
      ConfirmDialog.showToast(context, 'প্রথমে সদস্য যোগ করুন');
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => PaymentFormDialog(
        members: members,
        onSubmit: (memberId, date, amount, method, note) async {
          await data.addPayment(
            memberId: memberId,
            date: date,
            amount: amount,
            method: method,
            note: note,
          );
          if (mounted) ConfirmDialog.showToast(context, 'পেমেন্ট যোগ হয়েছে');
        },
      ),
    );
  }

  Future<void> _editPayment(Payment p) async {
    final data = context.read<DataProvider>();
    await showDialog(
      context: context,
      builder: (_) => PaymentFormDialog(
        existing: p,
        members: data.activeMembers,
        onSubmit: (memberId, date, amount, method, note) async {
          final updated = p.copyWith(
            date: date,
            amount: amount,
            paymentMethod: method,
            note: note,
          );
          await data.updatePayment(updated);
          if (mounted) ConfirmDialog.showToast(context, 'পেমেন্ট আপডেট হয়েছে');
        },
      ),
    );
  }

  Future<void> _deletePayment(Payment p) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'পেমেন্ট মুছুন',
      message: '${AppUtils.formatTaka(p.amount)} এর এই পেমেন্ট মুছে ফেলবেন?',
      confirmText: 'মুছুন',
      destructive: true,
    );
    if (ok) {
      final data = context.read<DataProvider>();
      await data.deletePayment(p.id);
      if (mounted) ConfirmDialog.showToast(context, 'পেমেন্ট মুছে ফেলা হয়েছে');
    }
  }
}

class PaymentFormDialog extends StatefulWidget {
  final Payment? existing;
  final List<dynamic> members;
  final Future<void> Function(String, DateTime, double, String, String) onSubmit;

  const PaymentFormDialog({
    super.key,
    this.existing,
    required this.members,
    required this.onSubmit,
  });

  @override
  State<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<PaymentFormDialog> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late DateTime _date;
  late String _memberId;
  late String _method;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? DateTime.now();
    _memberId = widget.existing?.memberId ?? _firstMemberId();
    _method = widget.existing?.paymentMethod ?? 'Cash';
    _amountCtrl.text =
        widget.existing != null ? '${widget.existing!.amount}' : '';
    _noteCtrl.text = widget.existing?.note ?? '';
  }

  String _firstMemberId() {
    if (widget.members.isEmpty) return '';
    final m = widget.members.first;
    return m.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memberNames = widget.members
        .map<DropdownMenuItem<String>>((m) =>
            DropdownMenuItem(value: m.id, child: Text(m.name)))
        .toList();

    return AlertDialog(
      title: Text(widget.existing == null ? 'নতুন পেমেন্ট' : 'পেমেন্ট সম্পাদনা'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _memberId,
              decoration: const InputDecoration(labelText: 'সদস্য'),
              items: memberNames,
              onChanged: (v) => setState(() => _memberId = v ?? ''),
            ),
            const SizedBox(height: 12),
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
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'পরিমাণ (৳) *',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'পেমেন্ট মাধ্যম'),
              items: AppConstants.paymentMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v ?? 'Cash'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'নোট (ঐচ্ছিক)',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined)),
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
    if (_memberId.isEmpty) {
      ConfirmDialog.showToast(context, 'সদস্য নির্বাচন করুন');
      return;
    }
    setState(() => _loading = true);
    await widget.onSubmit(
        _memberId, _date, amount, _method, _noteCtrl.text.trim());
    if (mounted) {
      Navigator.pop(context);
    }
  }
}