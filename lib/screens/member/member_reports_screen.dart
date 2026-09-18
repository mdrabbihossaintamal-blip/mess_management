import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';

class MemberReportsScreen extends StatelessWidget {
  const MemberReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final member = data.memberByUserId(auth.uid);
    final summary = data.summary;

    return Scaffold(
      appBar: AppBar(title: const Text('রিপোর্ট')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('মেসের মাসিক সারসংক্ষেপ', ''),
                  const SizedBox(height: 4),
                  _row('মোট মিল', AppUtils.formatAmount(summary?.monthTotalMeal ?? 0)),
                  _row('মোট খরচ', AppUtils.formatTaka(summary?.totalExpense ?? 0)),
                  _row('মোট সংগ্রহ', AppUtils.formatTaka(summary?.totalCollection ?? 0)),
                  _row('মিল রেট', AppUtils.formatTaka(summary?.mealRate ?? 0)),
                  _row('সক্রিয় সদস্য', '${summary?.activeMembers ?? 0}'),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('সদস্য বিন্যাস',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (summary == null)
                    const Text('তথ্য লোড হচ্ছে...')
                  else
                    ...summary.memberCalcs.map((c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c.memberName,
                                  style: const TextStyle(fontSize: 13)),
                              Text(
                                  '${AppUtils.formatAmount(c.totalMeal)} মিল '
                                  '• ${AppUtils.formatTaka(c.totalPaid)} জমা',
                                  style: const TextStyle(
                                      fontSize: 12, color: textSecondary)),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('* সদস্যদের ব্যক্তিগত খরচের তথ্য শুধুমাত্র অ্যাডমিন দেখতে পারেন',
              style: TextStyle(color: textSecondary, fontSize: 11)),
        ],
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
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}