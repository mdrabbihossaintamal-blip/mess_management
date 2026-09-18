import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  final String id;
  final String memberId;
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;
  final double totalMeal;
  final String createdBy;
  final DateTime updatedAt;
  final bool isDeleted;

  Meal({
    required this.id,
    required this.memberId,
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.totalMeal,
    this.createdBy = '',
    DateTime? updatedAt,
    this.isDeleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  double get total => breakfast + lunch + dinner;

  Map<String, dynamic> toMap() => {
        'id': id,
        'memberId': memberId,
        'date': Timestamp.fromDate(date),
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'totalMeal': totalMeal,
        'createdBy': createdBy,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isDeleted': isDeleted,
      };

  factory Meal.fromMap(Map<String, dynamic> map) => Meal(
        id: map['id'] ?? '',
        memberId: map['memberId'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        breakfast: (map['breakfast'] ?? 0).toDouble(),
        lunch: (map['lunch'] ?? 0).toDouble(),
        dinner: (map['dinner'] ?? 0).toDouble(),
        totalMeal: (map['totalMeal'] ?? 0).toDouble(),
        createdBy: map['createdBy'] ?? '',
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
        isDeleted: map['isDeleted'] ?? false,
      );

  Meal copyWith({
    double? breakfast,
    double? lunch,
    double? dinner,
    double? totalMeal,
    DateTime? updatedAt,
    bool? isDeleted,
  }) =>
      Meal(
        id: id,
        memberId: memberId,
        date: date,
        breakfast: breakfast ?? this.breakfast,
        lunch: lunch ?? this.lunch,
        dinner: dinner ?? this.dinner,
        totalMeal: totalMeal ?? this.totalMeal,
        createdBy: createdBy,
        updatedAt: updatedAt ?? DateTime.now(),
        isDeleted: isDeleted ?? this.isDeleted,
      );
}