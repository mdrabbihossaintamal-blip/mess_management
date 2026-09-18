import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String status; // 'active' or 'inactive'
  final DateTime joinDate;
  final double currentMonthMeals;
  final double currentBalance;

  Member({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.status = 'active',
    DateTime? joinDate,
    this.currentMonthMeals = 0,
    this.currentBalance = 0,
  }) : joinDate = joinDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'phone': phone,
        'status': status,
        'joinDate': Timestamp.fromDate(joinDate),
        'currentMonthMeals': currentMonthMeals,
        'currentBalance': currentBalance,
      };

  factory Member.fromMap(Map<String, dynamic> map) => Member(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        status: map['status'] ?? 'active',
        joinDate: (map['joinDate'] as Timestamp?)?.toDate(),
        currentMonthMeals: (map['currentMonthMeals'] ?? 0).toDouble(),
        currentBalance: (map['currentBalance'] ?? 0).toDouble(),
      );

  Member copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? status,
    DateTime? joinDate,
    double? currentMonthMeals,
    double? currentBalance,
  }) =>
      Member(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        status: status ?? this.status,
        joinDate: joinDate ?? this.joinDate,
        currentMonthMeals: currentMonthMeals ?? this.currentMonthMeals,
        currentBalance: currentBalance ?? this.currentBalance,
      );
}