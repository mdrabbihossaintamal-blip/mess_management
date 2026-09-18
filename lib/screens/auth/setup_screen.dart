import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mess_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _messNameCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminPhoneCtrl = TextEditingController();
  final _adminUsernameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _openingCashCtrl = TextEditingController(text: '0');
  final _breakfastCtrl = TextEditingController(text: '0.5');
  final _lunchCtrl = TextEditingController(text: '1');
  final _dinnerCtrl = TextEditingController(text: '1');
  bool _loading = false;

  @override
  void dispose() {
    _messNameCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminPhoneCtrl.dispose();
    _adminUsernameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _passwordCtrl.dispose();
    _openingCashCtrl.dispose();
    _breakfastCtrl.dispose();
    _lunchCtrl.dispose();
    _dinnerCtrl.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    final messName = _messNameCtrl.text.trim();
    final adminName = _adminNameCtrl.text.trim();
    final adminPhone = _adminPhoneCtrl.text.trim();
    final username = _adminUsernameCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;
    final openingCash = double.tryParse(_openingCashCtrl.text.trim()) ?? 0;
    final breakfast = double.tryParse(_breakfastCtrl.text.trim()) ?? 0.5;
    final lunch = double.tryParse(_lunchCtrl.text.trim()) ?? 1;
    final dinner = double.tryParse(_dinnerCtrl.text.trim()) ?? 1;

    if (messName.isEmpty ||
        adminName.isEmpty ||
        adminPhone.isEmpty ||
        username.isEmpty ||
        password.length < 4) {
      ConfirmDialog.showToast(context,
          'সমস্ত প্রয়োজনীয় তথ্য দিন (পাসওয়ার্ড ৪+ অক্ষর)');
      return;
    }
    setState(() => _loading = true);
    try {
      const authService = AuthService();

      final admin = await authService.createUser(
        name: adminName,
        phone: adminPhone,
        email: _adminEmailCtrl.text.trim(),
        username: username,
        password: password,
        role: 'admin',
        forceCreate: false,
      );

      final firestore = FirestoreService(authService);
      await firestore.createMess(
        MessSettings(
          messId: 'main',
          messName: messName,
          defaultBreakfast: breakfast,
          defaultLunch: lunch,
          defaultDinner: dinner,
          openingCash: openingCash,
          notificationsEnabled: false,
        ),
      );

      final now = DateTime.now();
      await firestore.startNewMonth(now.month, now.year);

      await firestore.addMember(
        userId: admin.id,
        name: adminName,
        phone: adminPhone,
        joinDate: now,
      );

      final authProvider = context.read<AuthProvider>();
      await authProvider.signIn(identifier: username, password: password);
      await context.read<DataProvider>().refresh();

      if (mounted) {
        ConfirmDialog.showToast(context, 'মেস সেটআপ সফল হয়েছে');
      }
    } catch (e) {
      if (mounted) {
        ConfirmDialog.showToast(
          context,
          'সেটআপ ব্যর্থ: ${e.toString().replaceFirst('Exception: ', '')}',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('মেস সেটআপ')),
      body: _loading
          ? const LoadingView(message: 'মেস তৈরি হচ্ছে...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle('মেস তথ্য'),
                  TextField(
                    controller: _messNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'মেসের নাম *',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _openingCashCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'প্রাথমিক নগদ ব্যালেন্স (৳)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('অ্যাডমিন অ্যাকাউন্ট'),
                  TextField(
                    controller: _adminNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'অ্যাডমিনের নাম *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _adminPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'ফোন নম্বর *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _adminUsernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ইউজারনেম *',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _adminEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'ইমেইল (ঐচ্ছিক)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'অ্যাডমিন পাসওয়ার্ড *',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('ডিফল্ট মিল মান'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _breakfastCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              const InputDecoration(labelText: 'নাস্তা'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lunchCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              const InputDecoration(labelText: 'দুপুর'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _dinnerCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(labelText: 'রাত'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _loading ? null : _setup,
                    child: const Text('মেস তৈরি করুন'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
      ),
    );
  }
}