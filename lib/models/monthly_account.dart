import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyAccount {
  final String id;
  final int month; // 1-12
  final int year;
  final double totalMeal;
  final double totalExpense;
  final double mealRate;
  final double totalCollection;
  final double openingCash;
  final double closingCash;
  final double otherIncome;
  final double totalCashIn;
  final double totalCashOut;
  final String status; // 'active', 'closed', 'reopened'
  final DateTime? closedAt;

  MonthlyAccount({
    required this.id,
    required this.month,
    required this.year,
    this.totalMeal = 0,
    this.totalExpense = 0,
    this.mealRate = 0,
    this.totalCollection = 0,
    this.openingCash = 0,
    this.closingCash = 0,
    this.otherIncome = 0,
    this.totalCashIn = 0,
    this.totalCashOut = 0,
    this.status = 'active',
    this.closedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'month': month,
        'year': year,
        'totalMeal': totalMeal,
        'totalExpense': totalExpense,
        'mealRate': mealRate,
        'totalCollection': totalCollection,
        'openingCash': openingCash,
        'closingCash': closingCash,
        'otherIncome': otherIncome,
        'totalCashIn': totalCashIn,
        'totalCashOut': totalCashOut,
        'status': status,
        'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      };

  factory MonthlyAccount.fromMap(Map<String, dynamic> map) => MonthlyAccount(
        id: map['id'] ?? '',
        month: map['month'] ?? DateTime.now().month,
        year: map['year'] ?? DateTime.now().year,
        totalMeal: (map['totalMeal'] ?? 0).toDouble(),
        totalExpense: (map['totalExpense'] ?? 0).toDouble(),
        mealRate: (map['mealRate'] ?? 0).toDouble(),
        totalCollection: (map['totalCollection'] ?? 0).toDouble(),
        openingCash: (map['openingCash'] ?? 0).toDouble(),
        closingCash: (map['closingCash'] ?? 0).toDouble(),
        otherIncome: (map['otherIncome'] ?? 0).toDouble(),
        totalCashIn: (map['totalCashIn'] ?? 0).toDouble(),
        totalCashOut: (map['totalCashOut'] ?? 0).toDouble(),
        status: map['status'] ?? 'active',
        closedAt: (map['closedAt'] as Timestamp?)?.toDate(),
      );

  String get monthLabel {
    const months = {
      1: 'January', 2: 'February', 3: 'March', 4: 'April',
      5: 'May', 6: 'June', 7: 'July', 8: 'August',
      9: 'September', 10: 'October', 11: 'November', 12: 'December',
    };
    return '${months[month] ?? ''} $year';
  }
}