import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/mess_calculator.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import 'member_account_detail_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final settings = data.settings;
    final summary = data.summary;

    return Scaffold(
      appBar: AppBar(
        title: Text(settings?.messName ?? 'মেস ড্যাশবোর্ড'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'রিপোর্ট',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'সেটিংস',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'লগআউট',
            onPressed: () async {
              final ok = await ConfirmDialog.show(
                context,
                title: 'লগআউট',
                message: 'আপনি কি লগআউট করতে চান?',
                confirmText: 'লগআউট',
              );
              if (ok) await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: data.isLoading && summary == null
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: () => data.refresh(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _greetingHeader(context, auth.user?.name ?? 'অ্যাডমিন', summaries: summary),
                  const SizedBox(height: 8),
                  _monthSelector(data),
                  if (summary != null) ...[
                    _statsGrid(summary),
                    const SizedBox(height: 12),
                    _memberBoard(context, data),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _greetingHeader(BuildContext context, String name, {DashboardSummary? summaries}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'স্বাগতম, $name 👋',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthSelector(DataProvider data) {
    final month = data.selectedMonth;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => data.setSelectedMonth(
                DateTime(month.year, month.month - 1, 1)),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${AppUtils.monthEnglish(month)} ${month.year}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final now = DateTime.now();
              final next = DateTime(month.year, month.month + 1, 1);
              if (next.isAfter(DateTime(now.year, now.month + 1, 1))) return;
              data.setSelectedMonth(next);
            },
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(DashboardSummary s) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        SummaryCard(
          icon: Icons.group_outlined,
          label: 'সদস্য',
          value: '${s.activeMembers}',
          color: primaryColor,
        ),
        SummaryCard(
          icon: Icons.restaurant_menu,
          label: 'আজকের মিল',
          value: AppUtils.formatAmount(s.todayTotalMeal),
          color: Colors.orange,
        ),
        SummaryCard(
          icon: Icons.calendar_month,
          label: 'মাসিক মিল',
          value: AppUtils.formatAmount(s.monthTotalMeal),
          color: Colors.teal,
        ),
        SummaryCard(
          icon: Icons.calculate_outlined,
          label: 'মিল রেট',
          value: AppUtils.formatTaka(s.mealRate),
          color: Colors.deepPurple,
        ),
        SummaryCard(
          icon: Icons.payments_outlined,
          label: 'মোট সংগ্রহ',
          value: AppUtils.formatTaka(s.totalCollection),
          color: Colors.green,
        ),
        SummaryCard(
          icon: Icons.shopping_cart_outlined,
          label: 'বাজার খরচ',
          value: AppUtils.formatTaka(s.totalExpense),
          color: Colors.red,
        ),
        SummaryCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'বর্তমান নগদ',
          value: AppUtils.formatTaka(s.currentCash),
          color: Colors.indigo,
        ),
        SummaryCard(
          icon: Icons.warning_amber_outlined,
          label: 'মোট বকেয়া',
          value: AppUtils.formatTaka(s.totalDue),
          color: s.totalDue > 0 ? dangerColor : Colors.green,
        ),
        SummaryCard(
          icon: Icons.trending_up,
          label: 'মোট অগ্রিম',
          value: AppUtils.formatTaka(s.totalAdvance),
          color: Colors.blueGrey,
        ),
      ],
    );
  }

  Widget _memberBoard(BuildContext context, DataProvider data) {
    final summary = data.summary;
    final calcs = summary?.memberCalcs ?? [];
    final rate = summary?.mealRate ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('সদস্যের অ্যাকাউন্ট',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Rate: ${AppUtils.formatTaka(rate)}',
                    style: const TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            if (calcs.isEmpty)
              const EmptyState(message: 'কোনো সদস্য নেই')
            else
              ...calcs.take(10).map((c) => InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MemberAccountDetailScreen(memberId: c.memberId),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.memberName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary)),
                                const SizedBox(height: 2),
                                Text(
                                  'মিল: ${AppUtils.formatAmount(c.totalMeal)}',
                                  style: const TextStyle(
                                      color: textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'খরচ: ${AppUtils.formatTaka(c.mealCost)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                c.due > 0
                                    ? 'বকেয়া: ${AppUtils.formatTaka(c.due)}'
                                    : c.advance > 0
                                        ? 'অগ্রিম: ${AppUtils.formatTaka(c.advance)}'
                                        : 'ব্যালেন্স: ৳0.00',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.due > 0
                                      ? dangerColor
                                      : c.advance > 0
                                          ? Colors.green
                                          : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('বিস্তারিত'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MemberAccountListScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MemberAccountListScreen extends StatelessWidget {
  const MemberAccountListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final calcs = data.summary?.memberCalcs ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('সদস্যদের অ্যাকাউন্ট')),
      body: calcs.isEmpty
          ? const EmptyState()
          : ListView.builder(
              itemCount: calcs.length,
              itemBuilder: (context, i) {
                final c = calcs[i];
                return Card(
                  child: ListTile(
                    title: Text(c.memberName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'মিল: ${AppUtils.formatAmount(c.totalMeal)}\n'
                        'খরচ: ${AppUtils.formatTaka(c.mealCost)}  '
                        'জমা: ${AppUtils.formatTaka(c.totalPaid)}'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (c.due > 0)
                          Text('বকেয়া ${AppUtils.formatTaka(c.due)}',
                              style: const TextStyle(
                                  color: dangerColor,
                                  fontWeight: FontWeight.w700))
                        else if (c.advance > 0)
                          Text('অগ্রিম ${AppUtils.formatTaka(c.advance)}',
                              style: TextStyle(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w700))
                        else
                          const Text('সমান',
                              style: TextStyle(color: textSecondary)),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MemberAccountDetailScreen(
                            memberId: c.memberId),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}