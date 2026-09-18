import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/data_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import 'member_account_detail_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final members = data.members;

    final filtered = members.where((m) {
      if (_query.isEmpty) return true;
      return m.name.toLowerCase().contains(_query.toLowerCase()) ||
          m.phone.contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('সদস্য'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'নতুন সদস্য',
            onPressed: () => _addMember(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'নাম বা ফোন দিয়ে খুঁজুন...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _query = ''),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(message: 'কোনো সদস্য নেই')
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final m = filtered[i];
                      final calc = data.summary?.memberCalcs
                          .where((c) => c.memberId == m.id)
                          .firstOrNull;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                m.status == 'active' ? primaryColor : Colors.grey,
                            child: Text(
                              m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(m.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${m.phone}\n'
                            'মিল: ${AppUtils.formatAmount(calc?.totalMeal ?? 0)}  '
                            '${calc != null && calc.due > 0 ? 'বকেয়া: ${AppUtils.formatTaka(calc.due)}' : calc != null && calc.advance > 0 ? 'অগ্রিম: ${AppUtils.formatTaka(calc.advance)}' : ''}',
                            maxLines: 2,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (m.status == 'inactive')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('নিষ্ক্রিয়',
                                      style: TextStyle(fontSize: 11)),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (v) => _handleMenu(v, m.id, m.name),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'detail',
                                      child: Text('অ্যাকাউন্ট')),
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text('সম্পাদনা')),
                                  PopupMenuItem(
                                      value: 'credentials',
                                      child: Text('লগইন তথ্য')),
                                  PopupMenuItem(
                                      value: 'toggle',
                                      child: Text('সক্রিয়/নিষ্ক্রিয়')),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemberAccountDetailScreen(
                                  memberId: m.id),
                            ),
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

  void _handleMenu(String value, String memberId, String name) {
    switch (value) {
      case 'detail':
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => MemberAccountDetailScreen(memberId: memberId)));
        break;
      case 'edit':
        _editMember(memberId);
        break;
      case 'credentials':
        _editCredentials(memberId);
        break;
      case 'toggle':
        _toggleStatus(memberId, name);
        break;
    }
  }

  Future<void> _addMember(BuildContext ctx) async {
    await showDialog(
      context: ctx,
      builder: (_) => MemberFormDialog(onSubmit: (name, phone, joinDate) async {
        try {
          const auth = AuthService();
          final created = await auth.createUser(
            name: name,
            phone: phone,
            email: '',
            username: _suggestUsername(name),
            password: '1234',
            role: 'member',
            forceCreate: true,
          );
          await ctx.read<DataProvider>().addMember(
                userId: created.id,
                name: name,
                phone: phone,
                joinDate: joinDate,
              );
          if (mounted) {
            ConfirmDialog.showToast(context, 'সদস্য যোগ হয়েছে\n'
                'ইউজারনেম: ${_suggestUsername(name)}\nপিন: 1234');
          }
        } catch (e) {
          if (mounted) {
            ConfirmDialog.showToast(
                context, 'ব্যর্থ: ${e.toString().replaceFirst('Exception: ', '')}',
                error: true);
          }
        }
      }),
    );
  }

  String _suggestUsername(String name) {
    final base = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '.');
    return base;
  }

  Future<void> _editMember(String memberId) async {
    final data = context.read<DataProvider>();
    final member = data.memberById(memberId);
    if (member == null) return;
    await showDialog(
      context: context,
      builder: (_) => MemberFormDialog(
        existingName: member.name,
        existingPhone: member.phone,
        existingJoinDate: member.joinDate,
        onSubmit: (name, phone, joinDate) async {
          await data.updateMember(
            userId: memberId,
            name: name,
            phone: phone,
          );
          if (mounted) ConfirmDialog.showToast(context, 'সদস্য আপডেট হয়েছে');
        },
      ),
    );
  }

  Future<void> _editCredentials(String memberId) async {
    final data = context.read<DataProvider>();
    final member = data.memberById(memberId);
    if (member == null) return;
    await showDialog(
      context: context,
      builder: (_) => CredentialsDialog(
        name: member.name,
        phone: member.phone,
        onSubmit: (name, phone, email, username, newPin) async {
          try {
            const auth = AuthService();
            await auth.updateCredentials(
              uid: memberId,
              name: name,
              phone: phone,
              email: email,
              username: username,
              newPassword: newPin,
            );
            await data.updateMember(
              userId: memberId,
              name: name,
              phone: phone,
            );
            if (mounted) {
              ConfirmDialog.showToast(context, 'লগইন তথ্য আপডেট হয়েছে');
            }
          } catch (e) {
            if (mounted) {
              ConfirmDialog.showToast(
                  context,
                  'ব্যর্থ: ${e.toString().replaceFirst('Exception: ', '')}',
                  error: true);
            }
          }
        },
      ),
    );
  }

  Future<void> _toggleStatus(String memberId, String name) async {
    final data = context.read<DataProvider>();
    final member = data.memberById(memberId);
    if (member == null) return;
    final newStatus = member.status == 'active' ? 'inactive' : 'active';
    final ok = await ConfirmDialog.show(
      context,
      title: newStatus == 'active' ? 'সদস্য সক্রিয় করুন' : 'সদস্য নিষ্ক্রিয় করুন',
      message: '$name কে ${newStatus == 'active' ? 'সক্রিয়' : 'নিষ্ক্রিয়'} করবেন?',
      confirmText: newStatus == 'active' ? 'সক্রিয়' : 'নিষ্ক্রিয়',
    );
    if (ok) {
      await data.toggleMemberStatus(memberId, newStatus);
      if (mounted) {
        ConfirmDialog.showToast(context,
            newStatus == 'active' ? 'সদস্য সক্রিয় হয়েছে' : 'সদস্য নিষ্ক্রিয় হয়েছে');
      }
    }
  }
}

class MemberFormDialog extends StatefulWidget {
  final String? existingName;
  final String? existingPhone;
  final DateTime? existingJoinDate;
  final Future<void> Function(String, String, DateTime) onSubmit;

  const MemberFormDialog({
    super.key,
    this.existingName,
    this.existingPhone,
    this.existingJoinDate,
    required this.onSubmit,
  });

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late DateTime _joinDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.existingName ?? '';
    _phoneCtrl.text = widget.existingPhone ?? '';
    _joinDate = widget.existingJoinDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingName == null ? 'নতুন সদস্য' : 'সদস্য সম্পাদনা'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'পূর্ণ নাম *', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'ফোন নম্বর *', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _joinDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _joinDate = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'যোগদান তারিখ',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(AppUtils.formatDate(_joinDate)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('বাতিল'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: Text(_loading ? 'সেভ হচ্ছে...' : 'সেভ করুন'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ConfirmDialog.showToast(context, 'নাম ও ফোন দিন');
      return;
    }
    setState(() => _loading = true);
    await widget.onSubmit(name, phone, _joinDate);
    if (mounted) Navigator.pop(context);
  }
}

class CredentialsDialog extends StatefulWidget {
  final String name;
  final String phone;
  final Future<void> Function(String, String, String, String, String) onSubmit;

  const CredentialsDialog({
    super.key,
    required this.name,
    required this.phone,
    required this.onSubmit,
  });

  @override
  State<CredentialsDialog> createState() => _CredentialsDialogState();
}

class _CredentialsDialogState extends State<CredentialsDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.name;
    _phoneCtrl.text = widget.phone;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('লগইন তথ্য'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'পূর্ণ নাম'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'ফোন'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                  labelText: 'ইউজারনেম *',
                  hintText: 'লগইন করতে ব্যবহৃত হবে'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'ইমেইল (ঐচ্ছিক)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'নতুন পিন / পাসওয়ার্ড',
                  hintText: 'খালি রাখলে পরিবর্তন হবে না'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('বাতিল'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: Text(_loading ? 'সেভ হচ্ছে...' : 'সেভ করুন'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final pin = _pinCtrl.text;
    if (username.isEmpty && pin.isEmpty) {
      ConfirmDialog.showToast(context, 'ইউজারনেম বা পিন দিন');
      return;
    }
    if (pin.isNotEmpty && pin.length < 4) {
      ConfirmDialog.showToast(context, 'পিন কমপক্ষে ৪ অক্ষর হতে হবে');
      return;
    }
    setState(() => _loading = true);
    await widget.onSubmit(
        _nameCtrl.text.trim(), _phoneCtrl.text.trim(),
        _emailCtrl.text.trim(), username, pin);
    if (mounted) Navigator.pop(context);
  }
}