import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/meal.dart';
import '../../models/payment.dart';
import '../../providers/data_provider.dart';
import '../../services/mess_calculator.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class MemberAccountDetailScreen extends StatefulWidget {
  final String memberId;
  const MemberAccountDetailScreen({super.key, required this.memberId});

  @override
  State<MemberAccountDetailScreen> createState() =>
      _MemberAccountDetailScreenState();
}

class _MemberAccountDetailScreenState extends State<MemberAccountDetailScreen> {
  List<Meal> _meals = [];
  List<Payment> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = Provider.of<DataProvider>(context, listen: false);
    _meals = data.monthMeals
        .where((m) => m.memberId == widget.memberId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _payments = data.monthPayments
        .where((p) => p.memberId == widget.memberId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final member = data.memberById(widget.memberId);
    final rate = data.summary?.mealRate ?? 0;

    final totalMeal = _meals.fold(0.0, (s, m) => s + m.totalMeal);
    final mealCost = totalMeal * rate;
    final totalPaid = _payments.fold(0.0, (s, p) => s + p.amount);
    final net = totalPaid - mealCost;
    final due = net < 0 ? net.abs() : 0;
    final advance = net > 0 ? net : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(member?.name ?? 'অ্যাকাউন্ট'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _row('মোট মিল', AppUtils.formatAmount(totalMeal)),
                        _row('মিল রেট', AppUtils.formatTaka(rate)),
                        _row('মিল খরচ', AppUtils.formatTaka(mealCost)),
                        const Divider(),
                        _row('মোট জমা', AppUtils.formatTaka(totalPaid)),
                        _row(
                          net < 0 ? 'বকেয়া' : 'অগ্রিম',
                          AppUtils.formatTaka(due > 0 ? due : advance),
                          color: net < 0 ? dangerColor : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('মাসের মিল',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                if (_meals.isEmpty)
                  const EmptyState(message: 'এই মাসে কোনো মিল নেই')
                else
                  ..._meals.map((m) => Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(AppUtils.formatDate(m.date)),
                          subtitle: Text(
                              'নাস্তা: ${_fmt(m.breakfast)} | দুপুর: ${_fmt(m.lunch)} | রাত: ${_fmt(m.dinner)}'),
                          trailing: Text(
                            _fmt(m.totalMeal),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      )),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('পেমেন্ট হিস্টরি',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                if (_payments.isEmpty)
                  const EmptyState(message: 'এই মাসে কোনো পেমেন্ট নেই')
                else
                  ..._payments.map((p) => Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.payments, color: Colors.white),
                          ),
                          title: Text(AppUtils.formatTaka(p.amount)),
                          subtitle: Text(
                              '${AppUtils.formatDate(p.date)} • ${p.paymentMethod}'),
                          trailing: Text(p.note.isNotEmpty ? p.note : ''),
                        ),
                      )),
              ],
            ),
    );
  }

  String _fmt(double v) => AppUtils.formatAmount(v);

  Widget _row(String label, String value, {Color color = textPrimary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 15)),
        ],
      ),
    );
  }
}