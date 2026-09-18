import 'package:cloud_firestore/cloud_firestore.dart';

class CashTransaction {
  final String id;
  final DateTime date;
  final String type; // 'in' or 'out'
  final String category; // 'payment', 'expense', 'opening', 'other_income', 'refund'
  final double amount;
  final String description;
  final String reference;
  final String createdBy;
  final DateTime createdAt;
  final bool isDeleted;

  CashTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    this.description = '',
    this.reference = '',
    this.createdBy = '',
    DateTime? createdAt,
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': Timestamp.fromDate(date),
        'type': type,
        'category': category,
        'amount': amount,
        'description': description,
        'reference': reference,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'isDeleted': isDeleted,
      };

  factory CashTransaction.fromMap(Map<String, dynamic> map) => CashTransaction(
        id: map['id'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        type: map['type'] ?? 'in',
        category: map['category'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        description: map['description'] ?? '',
        reference: map['reference'] ?? '',
        createdBy: map['createdBy'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        isDeleted: map['isDeleted'] ?? false,
      );
}