import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/meal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class MemberMealsScreen extends StatefulWidget {
  const MemberMealsScreen({super.key});

  @override
  State<MemberMealsScreen> createState() => _MemberMealsScreenState();
}

class _MemberMealsScreenState extends State<MemberMealsScreen> {
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

    final meals = data.monthMeals
        .where((m) =>
            m.memberId == memberId &&
            m.date.month == _month.month &&
            m.date.year == _month.year)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final total = meals.fold(0.0, (s, m) => s + m.totalMeal);
    final breakfast = meals.fold(0.0, (s, m) => s + m.breakfast);
    final lunch = meals.fold(0.0, (s, m) => s + m.lunch);
    final dinner = meals.fold(0.0, (s, m) => s + m.dinner);

    return Scaffold(
      appBar: AppBar(title: const Text('আমার মিল')),
      body: Column(
        children: [
          _monthRow(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('নাস্তা', breakfast.toStringAsFixed(1)),
                    _stat('দুপুর', lunch.toStringAsFixed(1)),
                    _stat('রাত', dinner.toStringAsFixed(1)),
                    _stat('মোট', total.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: meals.isEmpty
                ? const EmptyState(message: 'এই মাসে কোনো মিল নেই')
                : ListView.builder(
                    itemCount: meals.length,
                    itemBuilder: (context, i) {
                      final m = meals[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(AppUtils.formatDate(m.date)),
                          subtitle: Text(
                              'নাস্তা: ${AppUtils.formatAmount(m.breakfast)}  '
                              'দুপুর: ${AppUtils.formatAmount(m.lunch)}  '
                              'রাত: ${AppUtils.formatAmount(m.dinner)}'),
                          trailing: Text(
                            AppUtils.formatAmount(m.totalMeal),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: primaryColor),
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

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        Text(label,
            style: const TextStyle(
                color: textSecondary, fontSize: 12)),
      ],
    );
  }
}