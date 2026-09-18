import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../models/payment.dart';
import '../../providers/data_provider.dart';
import '../../services/report_service.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('রিপোর্ট')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DailyReportCard(),
          _MonthlyReportCard(),
          _MemberReportCard(),
          _ExpenseReportCard(),
          _PaymentReportCard(),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _DailyReportCard extends StatelessWidget {
  const _DailyReportCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.calendar_view_day_outlined,
      title: 'দৈনিক রিপোর্ট',
      subtitle: 'একটি নির্দিষ্ট দিনের মিল ও খরচের তালিকা',
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DailyReportScreen())),
    );
  }
}

class _MonthlyReportCard extends StatelessWidget {
  const _MonthlyReportCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.calendar_month_outlined,
      title: 'মাসিক রিপোর্ট',
      subtitle: 'মাসিক সারসংক্ষেপ ও ক্লোজড অ্যাকাউন্ট',
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const MonthlyReportScreen())),
    );
  }
}

class _MemberReportCard extends StatelessWidget {
  const _MemberReportCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.group_outlined,
      title: 'সদস্য রিপোর্ট',
      subtitle: 'প্রতিটি সদস্যের মিল, খরচ, জমা, বকেয়া/অগ্রিম',
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const MemberReportScreen())),
    );
  }
}

class _ExpenseReportCard extends StatelessWidget {
  const _ExpenseReportCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.shopping_cart_outlined,
      title: 'খরচ রিপোর্ট',
      subtitle: 'বিভাগ অনুযায়ী খরচের বিশ্লেষণ',
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ExpenseReportScreen())),
    );
  }
}

class _PaymentReportCard extends StatelessWidget {
  const _PaymentReportCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.payments_outlined,
      title: 'পেমেন্ট রিপোর্ট',
      subtitle: 'সদস্য অনুযায়ী জমার তালিকা',
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const PaymentReportScreen())),
    );
  }
}

// ------------------- DAILY -------------------
class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final rows = data.monthMeals
        .where((m) => AppUtils.isSameDay(m.date, _date))
        .toList();
    final rowsByName = rows.map((m) {
      final member = data.memberById(m.memberId);
      return {
        'member': member,
        'meal': m,
      };
    }).toList();

    final dayExpenses = data.monthExpenses
        .where((e) => AppUtils.isSameDay(e.date, _date))
        .toList();
    double dayExpense = 0;
    for (final e in dayExpenses) {
      dayExpense += e.amount;
    }

    double dayTotalMeal = 0;
    for (final r in rows) {
      dayTotalMeal += r.totalMeal;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('দৈনিক রিপোর্ট'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              final exportRows = rowsByName.map((r) {
                final m = r['meal'] as dynamic;
                return {
                  'name': (r['member'] as dynamic)?.name ?? 'সদস্য',
                  'breakfast': m.breakfast,
                  'lunch': m.lunch,
                  'dinner': m.dinner,
                  'total': m.totalMeal,
                };
              }).toList();
              final csv = await ReportService.buildDailyReportCsv(
                  date: _date, rows: exportRows);
              await ReportService.exportCsv(
                filename: 'daily_report_${_date.day}.csv',
                content: csv,
                share: true,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _dateRow(_date),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('মোট মিল',
                        style: TextStyle(color: textSecondary, fontSize: 12)),
                    Text(AppUtils.formatAmount(dayTotalMeal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                Column(
                  children: [
                    const Text('দৈনিক খরচ',
                        style: TextStyle(color: textSecondary, fontSize: 12)),
                    Text(AppUtils.formatTaka(dayExpense),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: dangerColor)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: rowsByName.isEmpty
                ? const EmptyState(message: 'এই দিনে কোনো মিল নেই')
                : ListView.builder(
                    itemCount: rowsByName.length,
                    itemBuilder: (context, i) {
                      final r = rowsByName[i];
                      final member = r['member'] as dynamic;
                      final meal = r['meal'] as dynamic;
                      return ListTile(
                        title: Text(member?.name ?? 'সদস্য'),
                        subtitle: Text(
                            'নাস্তা: ${AppUtils.formatAmount(meal.breakfast)}  '
                            'দুপুর: ${AppUtils.formatAmount(meal.lunch)}  '
                            'রাত: ${AppUtils.formatAmount(meal.dinner)}'),
                        trailing: Text(
                          AppUtils.formatAmount(meal.totalMeal),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: primaryColor),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dateRow(DateTime date) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                setState(() => _date = _date.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Center(
                child: Text(
                  AppUtils.formatDate(_date),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () =>
                setState(() => _date = _date.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}

// ------------------- MONTHLY -------------------
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final summary = data.summary;

    return Scaffold(
      appBar: AppBar(title: const Text('মাসিক রিপোর্ট')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _monthRow(),
          const SizedBox(height: 8),
          if (summary != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _stat('মোট সদস্য', '${summary.activeMembers}'),
                    _stat('মোট মিল', AppUtils.formatAmount(summary.monthTotalMeal)),
                    _stat('মোট খরচ', AppUtils.formatTaka(summary.totalExpense)),
                    _stat('মিল রেট', AppUtils.formatTaka(summary.mealRate)),
                    _stat('মোট সংগ্রহ', AppUtils.formatTaka(summary.totalCollection)),
                    const Divider(),
                    _stat('প্রাথমিক নগদ', AppUtils.formatTaka(summary.openingCash)),
                    _stat('মোট ইন', AppUtils.formatTaka(summary.totalCashIn)),
                    _stat('মোট আউট', AppUtils.formatTaka(summary.totalCashOut)),
                    _stat('বর্তমান নগদ', AppUtils.formatTaka(summary.currentCash),
                        color: summary.currentCash < 0 ? dangerColor : Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.ios_share),
              label: const Text('CSV এক্সপোর্ট করুন'),
              onPressed: () async {
                final memberAccounts = await data.getClosedMemberAccounts();
                final account = await data.getActiveAccountForReport(_month);
                if (account != null) {
                  await ReportService.exportMonthlyReport(
                    account: account,
                    members: memberAccounts,
                  );
                } else {
                  ConfirmDialog.showToast(context, 'মাসের অ্যাকাউন্ট নেই');
                }
              },
            ),
          ],
          const SizedBox(height: 12),
          Text('ক্লোজড মাসসমূহ',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: themePrimary)),
          const SizedBox(height: 6),
          ...data.monthlyAccounts
              .where((a) => a.status == 'closed')
              .map((a) => Card(
                    child: ListTile(
                      title: Text(a.monthLabel),
                      subtitle: Text(
                          'মিল: ${AppUtils.formatAmount(a.totalMeal)} • রেট: ${AppUtils.formatTaka(a.mealRate)}'
                          '\nবন্ধ নগদ: ${AppUtils.formatTaka(a.closingCash)}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.lock_outline),
                    ),
                  )),
        ],
      ),
    );
  }

  Color get themePrimary => const Color(0xFF1E88E5);

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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month + 1, 1)),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, {Color color = textPrimary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: color, fontSize: 15)),
        ],
      ),
    );
  }
}

// ------------------- MEMBER -------------------
class MemberReportScreen extends StatelessWidget {
  const MemberReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final calcs = data.summary?.memberCalcs ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('সদস্য রিপোর্ট')),
      body: calcs.isEmpty
          ? const EmptyState()
          : ListView.builder(
              itemCount: calcs.length,
              itemBuilder: (context, i) {
                final c = calcs[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.memberName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        _row('মোট নাস্তা', '--'),
                        _row('মোট দুপুর', '--'),
                        _row('মোট রাত', '--'),
                        _row('মোট মিল', AppUtils.formatAmount(c.totalMeal)),
                        _row('মিল খরচ', AppUtils.formatTaka(c.mealCost)),
                        _row('মোট জমা', AppUtils.formatTaka(c.totalPaid)),
                        _row('বকেয়া', AppUtils.formatTaka(c.due),
                            color: c.due > 0 ? dangerColor : textSecondary),
                        _row('অগ্রিম', AppUtils.formatTaka(c.advance),
                            color: c.advance > 0 ? Colors.green : textSecondary),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _row(String label, String value, {Color color = textPrimary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

// ------------------- EXPENSE -------------------
class ExpenseReportScreen extends StatelessWidget {
  const ExpenseReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final expenses = data.monthExpenses;

    final byCategory = <String, double>{};
    double total = 0;
    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
      total += e.amount;
    }
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('খরচ রিপোর্ট'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              final rows = expenses.map((e) => {
                    'date': e.date,
                    'category': e.category,
                    'description': e.description,
                    'amount': e.amount,
                    'paidBy': e.paidBy,
                  }).toList();
              final csv = await ReportService.buildExpenseReportCsv(rows: rows);
              await ReportService.exportCsv(
                filename: 'expense_report.csv',
                content: csv,
                share: true,
              );
            },
          ),
        ],
      ),
      body: sorted.isEmpty
          ? const EmptyState(message: 'এই মাসে কোনো খরচ নেই')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dangerColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('মোট খরচ',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(AppUtils.formatTaka(total),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: dangerColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...sorted.map((e) => Card(
                      child: ListTile(
                        title: Text(e.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        trailing: Text(
                          AppUtils.formatTaka(e.value),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}

// ------------------- PAYMENT -------------------
class PaymentReportScreen extends StatelessWidget {
  const PaymentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final payments = data.monthPayments;
    final byMember = <String, double>{};
    double total = 0;
    for (final p in payments) {
      byMember[p.memberId] = (byMember[p.memberId] ?? 0) + p.amount;
      total += p.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('পেমেন্ট রিপোর্ট'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              final rows = payments.map((p) => {
                    'date': p.date,
                    'member': data.memberById(p.memberId)?.name ?? 'সদস্য',
                    'amount': p.amount,
                    'method': p.paymentMethod,
                    'note': p.note,
                  }).toList();
              final csv = await ReportService.buildPaymentReportCsv(rows: rows);
              await ReportService.exportCsv(
                filename: 'payment_report.csv',
                content: csv,
                share: true,
              );
            },
          ),
        ],
      ),
      body: payments.isEmpty
          ? const EmptyState(message: 'এই মাসে কোনো পেমেন্ট নেই')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('মোট সংগ্রহ',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(AppUtils.formatTaka(total),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.green)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...byMember.entries.map((e) => Card(
                      child: ListTile(
                        title: Text(
                            data.memberById(e.key)?.name ?? 'সদস্য',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: Text(
                          AppUtils.formatTaka(e.value),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}