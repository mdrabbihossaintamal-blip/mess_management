import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final DateTime date;
  final String category;
  final String description;
  final double amount;
  final String paidBy;
  final String note;
  final String createdBy;
  final DateTime createdAt;
  final bool isDeleted;

  Expense({
    required this.id,
    required this.date,
    required this.category,
    this.description = '',
    required this.amount,
    required this.paidBy,
    this.note = '',
    this.createdBy = '',
    DateTime? createdAt,
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': Timestamp.fromDate(date),
        'category': category,
        'description': description,
        'amount': amount,
        'paidBy': paidBy,
        'note': note,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'isDeleted': isDeleted,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        category: map['category'] ?? '',
        description: map['description'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        paidBy: map['paidBy'] ?? '',
        note: map['note'] ?? '',
        createdBy: map['createdBy'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        isDeleted: map['isDeleted'] ?? false,
      );

  Expense copyWith({
    DateTime? date,
    String? category,
    String? description,
    double? amount,
    String? paidBy,
    String? note,
    bool? isDeleted,
  }) =>
      Expense(
        id: id,
        date: date ?? this.date,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        paidBy: paidBy ?? this.paidBy,
        note: note ?? this.note,
        createdBy: createdBy,
        createdAt: createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}