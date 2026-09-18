class MonthlyMemberAccount {
  final String id;
  final String monthlyAccountId;
  final String memberId;
  final String memberName;
  final double totalMeal;
  final double mealCost;
  final double totalPaid;
  final double due;
  final double advance;

  MonthlyMemberAccount({
    required this.id,
    required this.monthlyAccountId,
    required this.memberId,
    this.memberName = '',
    this.totalMeal = 0,
    this.mealCost = 0,
    this.totalPaid = 0,
    this.due = 0,
    this.advance = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'monthlyAccountId': monthlyAccountId,
        'memberId': memberId,
        'memberName': memberName,
        'totalMeal': totalMeal,
        'mealCost': mealCost,
        'totalPaid': totalPaid,
        'due': due,
        'advance': advance,
      };

  factory MonthlyMemberAccount.fromMap(Map<String, dynamic> map) =>
      MonthlyMemberAccount(
        id: map['id'] ?? '',
        monthlyAccountId: map['monthlyAccountId'] ?? '',
        memberId: map['memberId'] ?? '',
        memberName: map['memberName'] ?? '',
        totalMeal: (map['totalMeal'] ?? 0).toDouble(),
        mealCost: (map['mealCost'] ?? 0).toDouble(),
        totalPaid: (map['totalPaid'] ?? 0).toDouble(),
        due: (map['due'] ?? 0).toDouble(),
        advance: (map['advance'] ?? 0).toDouble(),
      );
}