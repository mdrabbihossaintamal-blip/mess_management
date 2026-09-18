import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/meals_screen.dart';
import '../screens/admin/bazar_screen.dart';
import '../screens/admin/payments_screen.dart';
import '../screens/admin/members_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/member/member_dashboard_screen.dart';
import '../screens/member/member_meals_screen.dart';
import '../screens/member/member_payments_screen.dart';
import '../screens/member/member_balance_screen.dart';
import '../screens/member/member_reports_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    final adminScreens = const [
      AdminDashboardScreen(),
      MealsScreen(),
      BazarScreen(),
      PaymentsScreen(),
      MembersScreen(),
      ReportsScreen(),
      SettingsScreen(),
    ];

    final memberScreens = const [
      MemberDashboardScreen(),
      MemberMealsScreen(),
      MemberPaymentsScreen(),
      MemberBalanceScreen(),
      MemberReportsScreen(),
    ];

    List<Widget> screens = isAdmin ? adminScreens : memberScreens;

    final currentIndex = _index < screens.length ? _index : 0;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => _index = i),
        items: isAdmin
            ? const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'ড্যাশবোর্ড'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.restaurant_menu),
                    label: 'মিল'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart_outlined),
                    activeIcon: Icon(Icons.shopping_cart),
                    label: 'বাজার'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.payments_outlined),
                    activeIcon: Icon(Icons.payments),
                    label: 'পেমেন্ট'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.group_outlined),
                    activeIcon: Icon(Icons.group),
                    label: 'সদস্য'),
              ]
            : const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'ড্যাশবোর্ড'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.restaurant_menu),
                    label: 'মাই মিল'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.payments_outlined),
                    activeIcon: Icon(Icons.payments),
                    label: 'পেমেন্ট'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    activeIcon: Icon(Icons.account_balance_wallet),
                    label: 'ব্যালেন্স'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.description_outlined),
                    activeIcon: Icon(Icons.description),
                    label: 'রিপোর্ট'),
              ],
      ),
    );
  }
}