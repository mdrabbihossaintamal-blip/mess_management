import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String memberId;
  final DateTime date;
  final double amount;
  final String paymentMethod; // Cash, bKash, Nagad, Bank, Other
  final String note;
  final String createdBy;
  final DateTime createdAt;
  final bool isDeleted;

  Payment({
    required this.id,
    required this.memberId,
    required this.date,
    required this.amount,
    this.paymentMethod = 'Cash',
    this.note = '',
    this.createdBy = '',
    DateTime? createdAt,
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'memberId': memberId,
        'date': Timestamp.fromDate(date),
        'amount': amount,
        'paymentMethod': paymentMethod,
        'note': note,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'isDeleted': isDeleted,
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] ?? '',
        memberId: map['memberId'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        amount: (map['amount'] ?? 0).toDouble(),
        paymentMethod: map['paymentMethod'] ?? 'Cash',
        note: map['note'] ?? '',
        createdBy: map['createdBy'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        isDeleted: map['isDeleted'] ?? false,
      );

  Payment copyWith({
    DateTime? date,
    double? amount,
    String? paymentMethod,
    String? note,
    bool? isDeleted,
  }) =>
      Payment(
        id: id,
        memberId: memberId,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        note: note ?? this.note,
        createdBy: createdBy,
        createdAt: createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}