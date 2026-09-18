import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class MemberPaymentsScreen extends StatefulWidget {
  const MemberPaymentsScreen({super.key});

  @override
  State<MemberPaymentsScreen> createState() => _MemberPaymentsScreenState();
}

class _MemberPaymentsScreenState extends State<MemberPaymentsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final member = data.memberByUserId(auth.uid);
    final memberId = member?.id ?? auth.uid;

    final payments = data.monthPayments
        .where((p) =>
            p.memberId == memberId &&
            p.date.month == _month.month &&
            p.date.year == _month.year)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final total = payments.fold(0.0, (s, p) => s + p.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('আমার পেমেন্ট')),
      body: Column(
        children: [
          _monthRow(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('মোট জমা', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(AppUtils.formatTaka(total),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.green)),
              ],
            ),
          ),
          Expanded(
            child: payments.isEmpty
                ? const EmptyState(message: 'এই মাসে কোনো পেমেন্ট নেই')
                : ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, i) {
                      final p = payments[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.payments, color: Colors.white),
                          ),
                          title: Text(AppUtils.formatTaka(p.amount),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${AppUtils.formatDate(p.date)} • ${p.paymentMethod}'
                              '${p.note.isNotEmpty ? '\n${p.note}' : ''}'),
                          isThreeLine: p.note.isNotEmpty,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _monthRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month - 1, 1)),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${AppUtils.monthEnglish(_month)} ${_month.year}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final now = DateTime.now();
            if (_month.isBefore(DateTime(now.year, now.month, 1))) {
              setState(() => _month = DateTime(_month.year, _month.month + 1, 1));
            }
          },
        ),
      ],
    );
  }
}