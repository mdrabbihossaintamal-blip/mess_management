import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Adds realistic sample data to Firestore so dashboards and reports
/// can be verified without manually entering everything.
class SeedService {
  static bool _seeded = false;

  static Future<void> maybeSeed(BuildContext context) async {
    if (_seeded) return;
    _seeded = true;

    final db = FirebaseFirestore.instance;
    final snap = await db.collection('members').limit(1).get();
    if (snap.docs.isNotEmpty) return; // data already exists

    debugPrint('Seeding Firestore with sample data...');

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    const names = [
      'Rahim', 'Karim', 'Hasan', 'Sakib', 'Nayeem',
      'Rafi', 'Fahim', 'Imran', 'Tanvir', 'Arif',
    ];

    for (int i = 0; i < names.length; i++) {
      final uid = 'member_$i';
      final username = names[i].toLowerCase();
      final email = '$username@mess.local';

      await db.collection('users').doc(uid).set({
        'id': uid,
        'name': names[i],
        'phone': '01712345${(1000 + i).toString()}',
        'email': email,
        'username': username,
        'passwordHash': '',
        'role': 'member',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await db.collection('lookup').doc(username).set({
        'uid': uid,
        'role': 'member',
        'name': names[i],
        'email': email,
      });
      await db.collection('members').doc(uid).set({
        'id': uid,
        'userId': uid,
        'name': names[i],
        'phone': '01712345${(1000 + i).toString()}',
        'status': 'active',
        'joinDate': Timestamp.fromDate(now.subtract(const Duration(days: 120))),
        'currentMonthMeals': 0,
        'currentBalance': 0,
      });
    }

    // Meals for last 5 days
    final randomMeals = [
      [0.5, 1.0, 1.0],
      [0.5, 1.0, 1.0],
      [0.0, 1.0, 1.0],
      [0.5, 1.0, 1.0],
      [0.5, 0.0, 1.0],
      [0.5, 1.0, 1.0],
      [0.5, 1.0, 1.0],
      [0.0, 1.0, 1.0],
      [0.5, 1.0, 1.0],
      [0.5, 1.0, 1.0],
    ];

    for (int day = 0; day < 5; day++) {
      final date = DateTime(year, month, now.day - day);
      for (int i = 0; i < names.length; i++) {
        final m = randomMeals[i];
        final total = m[0] + m[1] + m[2];
        if (total <= 0) continue;
        await db.collection('meals').doc('seed_${date.day}_$i').set({
          'id': 'seed_${date.day}_$i',
          'memberId': 'member_$i',
          'date': Timestamp.fromDate(date),
          'breakfast': m[0],
          'lunch': m[1],
          'dinner': m[2],
          'totalMeal': total,
          'createdBy': '',
          'updatedAt': FieldValue.serverTimestamp(),
          'isDeleted': false,
        });
      }
    }

    // Expenses for last 5 days
    const cats = ['Rice', 'Fish', 'Meat', 'Vegetable', 'Dal'];
    final amounts = [1200.0, 800.0, 600.0, 350.0, 200.0];
    for (int day = 0; day < 5; day++) {
      final date = DateTime(year, month, now.day - day);
      for (int e = 0; e < 3; e++) {
        final idx = (day + e) % cats.length;
        final expId = 'exp_${date.day}_$e';
        await db.collection('expenses').doc(expId).set({
          'id': expId,
          'date': Timestamp.fromDate(date),
          'category': cats[idx],
          'description': 'Daily ${cats[idx]}',
          'amount': amounts[idx],
          'paidBy': 'member_0',
          'note': '',
          'createdBy': '',
          'createdAt': FieldValue.serverTimestamp(),
          'isDeleted': false,
        });
      }
    }

    // Payments
    final payAmounts = [6000.0, 5500.0, 5000.0, 5000.0, 4500.0,
        4000.0, 4500.0, 4000.0, 3500.0, 3000.0];
    for (int i = 0; i < names.length; i++) {
      await db.collection('payments').doc('pay_$i').set({
        'id': 'pay_$i',
        'memberId': 'member_$i',
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        'amount': payAmounts[i],
        'paymentMethod': 'Cash',
        'note': 'Seed payment',
        'createdBy': '',
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
      });
    }

    debugPrint('Sample data seeded successfully');
  }
}