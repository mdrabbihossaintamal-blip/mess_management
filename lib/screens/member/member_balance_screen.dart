import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/meal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class MemberBalanceScreen extends StatelessWidget {
  const MemberBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final member = data.memberByUserId(auth.uid);
    final memberId = member?.id ?? auth.uid;
    final summary = data.summary;

    double myMeal = 0;
    double myPaid = 0;
    double myCost = 0;
    if (summary != null) {
      for (final c in summary.memberCalcs) {
        if (c.memberId == memberId) {
          myMeal = c.totalMeal;
          myCost = c.mealCost;
          myPaid = c.totalPaid;
        }
      }
    }
    final rate = summary?.mealRate ?? 0;
    final net = myPaid - myCost;
    final due = net < 0 ? net.abs() : 0;
    final advance = net > 0 ? net : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('আমার ব্যালেন্স')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    due > 0 ? 'বকেয়া' : advance > 0 ? 'অগ্রিম' : 'ব্যালেন্স',
                    style: const TextStyle(color: textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppUtils.formatTaka(due > 0 ? due : advance),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: due > 0
                          ? dangerColor
                          : advance > 0
                              ? Colors.green
                              : textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('মোট মিল', AppUtils.formatAmount(myMeal)),
                  _row('মিল রেট', AppUtils.formatTaka(rate)),
                  _row('মিল খরচ', AppUtils.formatTaka(myCost)),
                  const Divider(),
                  _row('মোট জমা', AppUtils.formatTaka(myPaid)),
                  _row(
                    'বকেয়া',
                    AppUtils.formatTaka(due),
                    color: due > 0 ? dangerColor : textSecondary,
                  ),
                  _row(
                    'অগ্রিম',
                    AppUtils.formatTaka(advance),
                    color: advance > 0 ? Colors.green : textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('এই মাসের ব্যালেন্স হিস্টরি',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          _BalanceHistoryList(memberId: memberId),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color color = textPrimary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textSecondary)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _BalanceHistoryList extends StatelessWidget {
  final String memberId;
  const _BalanceHistoryList({required this.memberId});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final summary = data.summary;
    if (summary == null) return const SizedBox.shrink();

    final rate = summary.mealRate;
    // Build cumulative history day by day: meal cost minus payments
    final entries = <Map<String, dynamic>>[];

    final meals = data.monthMeals
        .where((m) => m.memberId == memberId)
        .toList();
    final payments = data.monthPayments
        .where((p) => p.memberId == memberId)
        .toList();

    final allDates = <DateTime>{};
    for (final m in meals) {
      allDates.add(DateTime(m.date.year, m.date.month, m.date.day));
    }
    for (final p in payments) {
      allDates.add(DateTime(p.date.year, p.date.month, p.date.day));
    }
    final sortedDates = allDates.toList()..sort();

    double runningCost = 0;
    double runningPaid = 0;
    for (final d in sortedDates) {
      for (final m in meals) {
        if (m.date.year == d.year && m.date.month == d.month && m.date.day == d.day) {
          runningCost += m.totalMeal * rate;
        }
      }
      for (final p in payments) {
        if (p.date.year == d.year && p.date.month == d.month && p.date.day == d.day) {
          runningPaid += p.amount;
        }
      }
      final balance = runningPaid - runningCost;
      entries.add({
        'date': d,
        'balance': balance,
        'paid': runningPaid,
        'cost': runningCost,
      });
    }
    entries.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (entries.isEmpty) {
      return const EmptyState(message: 'এই মাসে কোনো লেনদেন নেই');
    }

    return Column(
      children: entries.take(30).map((e) {
        final balance = e['balance'] as double;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            dense: true,
            title: Text(AppUtils.formatDate(e['date'] as DateTime)),
            subtitle: Text(
                'খরচ: ${AppUtils.formatTaka(e['cost'] as double)}\n'
                'জমা: ${AppUtils.formatTaka(e['paid'] as double)}'),
            isThreeLine: true,
            trailing: Text(
              AppUtils.formatTaka(balance),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: balance < 0 ? dangerColor : Colors.green,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}