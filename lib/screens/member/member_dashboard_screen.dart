import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/meal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class MemberDashboardScreen extends StatelessWidget {
  const MemberDashboardScreen({super.key});

  String _resolveMemberId(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final data = context.read<DataProvider>();
    final member = data.memberByUserId(auth.uid);
    if (member != null) return member.id;
    return auth.uid;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final member = data.memberByUserId(auth.uid);

    final memberId = member?.id ?? auth.uid;

    if (member?.status == 'inactive') {
      return Scaffold(
        appBar: AppBar(title: const Text('মেস ম্যানেজমেন্ট')),
        body: const Center(
          child: Text('এই সদস্যটি নিষ্ক্রিয়।\nঅ্যাডমিনের সাথে যোগাযোগ করুন।',
              textAlign: TextAlign.center),
        ),
      );
    }

    // Summary for a single member: reuse the admin computation
    return FutureBuilder<DashboardSummaryPlaceholder?>(
      future: _computeMemberSummary(context, memberId),
      builder: (context, snap) {
        final summary = snap.data;
        final name = member?.name ?? auth.user?.name ?? 'সদস্য';
        return Scaffold(
          appBar: AppBar(title: Text(data.settings?.messName ?? 'মেস')),
          body: RefreshIndicator(
            onRefresh: () => data.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _welcome(name, summary?.monthTotalMeal ?? 0),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _row('আমার মিল', AppUtils.formatAmount(summary?.memberTotalMeal ?? 0)),
                        _row('মিল রেট', AppUtils.formatTaka(summary?.mealRate ?? 0)),
                        _row('আমার মিল খরচ', AppUtils.formatTaka(summary?.memberCost ?? 0)),
                        _row('মোট জমা', AppUtils.formatTaka(summary?.memberPaid ?? 0)),
                        const Divider(),
                        if ((summary?.memberDue ?? 0) > 0)
                          _row('বকেয়া', AppUtils.formatTaka(summary!.memberDue),
                              color: dangerColor)
                        else if ((summary?.memberAdvance ?? 0) > 0)
                          _row('অগ্রিম', AppUtils.formatTaka(summary!.memberAdvance),
                              color: Colors.green)
                        else
                          _row('ব্যালেন্স', '৳0.00'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _TodayMealCard(),
                const SizedBox(height: 12),
                _MessSummaryCard(
                  summary: summary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<DashboardSummaryPlaceholder?> _computeMemberSummary(
      BuildContext context, String memberId) async {
    final data = context.read<DataProvider>();
    if (data.summary == null) return null;
    final s = data.summary!;
    MemberCalcPlaceholder? mine;
    double myCost = 0;
    double myPaid = 0;
    for (final c in s.memberCalcs) {
      if (c.memberId == memberId) {
        mine = MemberCalcPlaceholder(c.totalMeal, c.mealCost, c.totalPaid);
        myCost = c.mealCost;
        myPaid = c.totalPaid;
      }
    }
    final net = myPaid - myCost;
    return DashboardSummaryPlaceholder(
      monthTotalMeal: s.monthTotalMeal,
      mealRate: s.mealRate,
      memberTotalMeal: mine?.totalMeal ?? 0,
      memberCost: myCost,
      memberPaid: myPaid,
      memberDue: net < 0 ? net.abs() : 0,
      memberAdvance: net > 0 ? net : 0,
      totalExpense: s.totalExpense,
      totalCollection: s.totalCollection,
    );
  }

  Widget _welcome(String name, double myMeal) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: primaryColor,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('স্বাগতম, ${name.toUpperCase()}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary)),
            Text('এই মাসের মিল: ${AppUtils.formatAmount(myMeal)}',
                style: const TextStyle(color: textSecondary, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value, {Color color = textPrimary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class MemberCalcPlaceholder {
  final double totalMeal;
  final double mealCost;
  final double totalPaid;
  MemberCalcPlaceholder(this.totalMeal, this.mealCost, this.totalPaid);
}

class DashboardSummaryPlaceholder {
  final double monthTotalMeal;
  final double mealRate;
  final double memberTotalMeal;
  final double memberCost;
  final double memberPaid;
  final double memberDue;
  final double memberAdvance;
  final double totalExpense;
  final double totalCollection;

  DashboardSummaryPlaceholder({
    required this.monthTotalMeal,
    required this.mealRate,
    required this.memberTotalMeal,
    required this.memberCost,
    required this.memberPaid,
    required this.memberDue,
    required this.memberAdvance,
    required this.totalExpense,
    required this.totalCollection,
  });
}

class _TodayMealCard extends StatelessWidget {
  const _TodayMealCard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final member = data.memberByUserId(auth.uid);
    final memberId = member?.id ?? auth.uid;

    Meal? today;
    for (final m in data.monthMeals) {
      if (m.memberId == memberId && AppUtils.isSameDay(m.date, DateTime.now())) {
        today = m;
        break;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('আজকের মিল',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (today == null)
              const Text('আজকের মিল এখনো এন্ট্রি হয়নি',
                  style: TextStyle(color: textSecondary))
            else ...[
              _row('নাস্তা', AppUtils.formatAmount(today.breakfast)),
              _row('দুপুর', AppUtils.formatAmount(today.lunch)),
              _row('রাত', AppUtils.formatAmount(today.dinner)),
              const Divider(),
              _row('মোট', AppUtils.formatAmount(today.totalMeal),
                  color: primaryColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color color = textPrimary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class _MessSummaryCard extends StatelessWidget {
  final DashboardSummaryPlaceholder? summary;
  const _MessSummaryCard({this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('এই মাসের মেস সারসংক্ষেপ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _row('মোট মিল', AppUtils.formatAmount(summary?.monthTotalMeal ?? 0)),
            _row('মোট খরচ', AppUtils.formatTaka(summary?.totalExpense ?? 0)),
            _row('মোট সংগ্রহ', AppUtils.formatTaka(summary?.totalCollection ?? 0)),
            _row('মিল রেট', AppUtils.formatTaka(summary?.mealRate ?? 0)),
            const SizedBox(height: 6),
            const Text('* এই তথ্য শুধুমাত্র দেখার জন্য',
                style: TextStyle(color: textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}