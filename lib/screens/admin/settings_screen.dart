import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/monthly_account.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final settings = data.settings;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.home_outlined, color: primaryColor),
              title: const Text('মেসের নাম'),
              subtitle: Text(settings?.messName ?? 'মেস'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editMessName(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_input_component,
                  color: primaryColor),
              title: const Text('ডিফল্ট মিল মান'),
              subtitle: settings == null
                  ? const Text('লোড হচ্ছে...')
                  : Text(
                      'নাস্তা: ${AppUtils.formatAmount(settings.defaultBreakfast)}  '
                      'দুপুর: ${AppUtils.formatAmount(settings.defaultLunch)}  '
                      'রাত: ${AppUtils.formatAmount(settings.defaultDinner)}'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editMealDefaults(context),
            ),
          ),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.account_balance_wallet_outlined, color: primaryColor),
              title: const Text('প্রাথমিক নগদ ব্যালেন্স'),
              subtitle: Text(AppUtils.formatTaka(settings?.openingCash ?? 0)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editOpeningCash(context),
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined,
                  color: primaryColor),
              title: const Text('নোটিফিকেশন'),
              subtitle: const Text('মিল ও পেমেন্ট রিমাইন্ডার'),
              value: settings?.notificationsEnabled ?? false,
              onChanged: (v) {
                data.updateSettings(notificationsEnabled: v);
                if (mounted) {
                  ConfirmDialog.showToast(context,
                      v ? 'নোটিফিকেশন চালু হয়েছে' : 'নোটিফিকেশন বন্ধ হয়েছে');
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          const _MonthManagementSection(),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline, color: primaryColor),
              title: const Text('অ্যাডমিন অ্যাকাউন্ট'),
              subtitle: Text('${auth.user?.name ?? ''}\n${auth.user?.username ?? ''}'),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: () => _logout(context),
                child: const Text('লগআউট', style: TextStyle(color: dangerColor)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editMessName(BuildContext context) async {
    final data = context.read<DataProvider>();
    final ctrl = TextEditingController(text: data.settings?.messName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মেসের নাম'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('সেভ')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await data.updateSettings(messName: name);
      if (mounted) ConfirmDialog.showToast(context, 'আপডেট হয়েছে');
    }
  }

  Future<void> _editMealDefaults(BuildContext context) async {
    final data = context.read<DataProvider>();
    final s = data.settings;
    final b = TextEditingController(text: '${s?.defaultBreakfast ?? 0.5}');
    final l = TextEditingController(text: '${s?.defaultLunch ?? 1}');
    final d = TextEditingController(text: '${s?.defaultDinner ?? 1}');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ডিফল্ট মিল মান'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: b,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'নাস্তা')),
            const SizedBox(height: 10),
            TextField(
                controller: l,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'দুপুর')),
            const SizedBox(height: 10),
            TextField(
                controller: d,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'রাত')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('সেভ')),
        ],
      ),
    );
    await data.updateSettings(
      defaultBreakfast: double.tryParse(b.text) ?? 0.5,
      defaultLunch: double.tryParse(l.text) ?? 1,
      defaultDinner: double.tryParse(d.text) ?? 1,
    );
    if (mounted) ConfirmDialog.showToast(context, 'আপডেট হয়েছে');
  }

  Future<void> _editOpeningCash(BuildContext context) async {
    final data = context.read<DataProvider>();
    final ctrl = TextEditingController(
        text: '${data.settings?.openingCash ?? 0}');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('প্রাথমিক নগদ ব্যালেন্স'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
              labelText: '৳', prefixIcon: Icon(Icons.attach_money)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, double.tryParse(ctrl.text) ?? 0),
              child: const Text('সেভ')),
        ],
      ),
    );
    if (result != null) {
      // Recording as opening adjustment
      await data.addCashTransaction(
        type: result >= 0 ? 'in' : 'out',
        category: 'opening',
        amount: result.abs(),
        date: DateTime.now(),
        description: 'Opening cash adjustment',
      );
      if (mounted) ConfirmDialog.showToast(context, 'আপডেট হয়েছে');
    }
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().signOut();
  }
}

class _MonthManagementSection extends StatefulWidget {
  const _MonthManagementSection();

  @override
  State<_MonthManagementSection> createState() =>
      _MonthManagementSectionState();
}

class _MonthManagementSectionState extends State<_MonthManagementSection> {
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final account = data.activeAccount;
    final statusText = account == null
        ? 'কোনো অ্যাকাউন্ট নেই'
        : account.status == 'closed'
            ? 'ক্লোজড'
            : account.status == 'reopened'
                ? 'পুনরায় খোলা'
                : 'সক্রিয়';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: primaryColor),
                const SizedBox(width: 8),
                const Text('মাস ব্যবস্থাপনা',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1, 1)),
                ),
                Text(
                  '${AppUtils.monthEnglish(_month)} ${_month.year}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1, 1)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('স্ট্যাটাস', statusText),
                if (account != null) ...[
                  _chip('মোট মিল', AppUtils.formatAmount(account.totalMeal)),
                  _chip('রেট', AppUtils.formatTaka(account.mealRate)),
                  _chip('নগদ', AppUtils.formatTaka(account.closingCash)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _startNewMonth(context, data),
                    child: const Text('নতুন মাস শুরু'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('মাস ক্লোজ'),
                    onPressed: account != null && account.status != 'closed'
                        ? () => _closeMonth(context, data)
                        : null,
                  ),
                ),
              ],
            ),
            if (account != null && account.status != 'active')
              TextButton(
                onPressed: () => _reopenMonth(context, data, account),
                child: const Text('মাস পুনরায় খুলুন',
                    style: TextStyle(color: Colors.orange)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _closeMonth(BuildContext context, DataProvider data) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'মাস ক্লোজ করুন',
      message:
          '${AppUtils.monthEnglish(_month)} ${_month.year} এর হিসাব বন্ধ হবে।\n'
          'বন্ধ করার পর এই মাসের ডেটা লক হয়ে যাবে।\n'
          'আপনি কি নিশ্চিত?',
      confirmText: 'ক্লোজ করুন',
    );
    if (ok) {
      try {
        await data.closeMonth();
        if (mounted) {
          ConfirmDialog.showToast(context, 'মাস ক্লোজ হয়েছে');
        }
      } catch (e) {
        if (mounted) {
          ConfirmDialog.showToast(context,
              'ক্লোজ ব্যর্থ: ${e.toString().replaceFirst('Exception: ', '')}',
              error: true);
        }
      }
    }
  }

  Future<void> _startNewMonth(BuildContext context, DataProvider data) async {
    final next = DateTime(_month.year, _month.month + 1, 1);
    final ok = await ConfirmDialog.show(
      context,
      title: 'নতুন মাস',
      message: '${AppUtils.monthEnglish(next)} ${next.year} এর অ্যাকাউন্ট '
          'তৈরি হবে।\nএই মাসের বর্তমান নগদ ব্যালেন্স নতুন মাসের '
          'প্রাথমিক ব্যালেন্স হিসেবে বসবে।\nচালিয়ে যাবেন?',
      confirmText: 'শুরু করুন',
    );
    if (ok) {
      await data.startNewMonth(next.month, next.year);
      if (mounted) {
        ConfirmDialog.showToast(context, 'নতুন মাস শুরু হয়েছে');
      }
    }
  }

  Future<void> _reopenMonth(BuildContext context, DataProvider data,
      MonthlyAccount account) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'মাস পুনরায় খুলুন',
      message: 'ক্লোজড মাস ${account.monthLabel} আবার খোলা হবে। '
          'সংরক্ষিত হিসাব আবার সম্পাদনযোগ্য হবে।\nনিশ্চিত?',
      confirmText: 'খুলুন',
    );
    if (ok) {
      await data.reopenMonth(account.month, account.year);
      if (mounted) {
        ConfirmDialog.showToast(context, 'মাস পুনরায় খোলা হয়েছে');
      }
    }
  }
}