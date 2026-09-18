import '../models/monthly_account.dart';
import '../models/monthly_member_account.dart';
import '../models/member.dart';

class MemberCalc {
  final String memberId;
  final String memberName;
  double totalMeal;
  double mealCost;
  double totalPaid;
  double get due => mealCost - totalPaid > 0 ? mealCost - totalPaid : 0;
  double get advance => mealCost - totalPaid < 0 ? totalPaid - mealCost : 0;
  double get netBalance => totalPaid - mealCost;

  MemberCalc({
    required this.memberId,
    required this.memberName,
    this.totalMeal = 0,
    this.mealCost = 0,
    this.totalPaid = 0,
  });

  MemberCalc copy() => MemberCalc(
        memberId: memberId,
        memberName: memberName,
        totalMeal: totalMeal,
        mealCost: mealCost,
        totalPaid: totalPaid,
      );
}

class DashboardSummary {
  final int activeMembers;
  final double todayTotalMeal;
  final double monthTotalMeal;
  final double mealRate;
  final double totalCollection;
  final double totalExpense;
  final double openingCash;
  final double currentCash;
  final double totalCashIn;
  final double totalCashOut;
  final double totalDue;
  final double totalAdvance;
  final List<MemberCalc> memberCalcs;

  DashboardSummary({
    this.activeMembers = 0,
    this.todayTotalMeal = 0,
    this.monthTotalMeal = 0,
    this.mealRate = 0,
    this.totalCollection = 0,
    this.totalExpense = 0,
    this.openingCash = 0,
    this.currentCash = 0,
    this.totalCashIn = 0,
    this.totalCashOut = 0,
    this.totalDue = 0,
    this.totalAdvance = 0,
    this.memberCalcs = const [],
  });

  DashboardSummary copy() => DashboardSummary(
        activeMembers: activeMembers,
        todayTotalMeal: todayTotalMeal,
        monthTotalMeal: monthTotalMeal,
        mealRate: mealRate,
        totalCollection: totalCollection,
        totalExpense: totalExpense,
        openingCash: openingCash,
        currentCash: currentCash,
        totalCashIn: totalCashIn,
        totalCashOut: totalCashOut,
        totalDue: totalDue,
        totalAdvance: totalAdvance,
        memberCalcs: memberCalcs.map((m) => m.copy()).toList(),
      );
}

class MessCalculator {
  static double computeMealRate(double totalExpense, double totalMeal) {
    if (totalMeal <= 0) return 0;
    return totalExpense / totalMeal;
  }

  static List<MemberCalc> computeMemberAccounts({
    required List<Member> members,
    required Map<String, double> memberMeals,
    required Map<String, double> memberPayments,
    required double mealRate,
  }) {
    return members.map((m) {
      final meals = memberMeals[m.id] ?? 0.0;
      final paid = memberPayments[m.id] ?? 0.0;
      return MemberCalc(
        memberId: m.id,
        memberName: m.name,
        totalMeal: meals,
        mealCost: meals * mealRate,
        totalPaid: paid,
      );
    }).toList();
  }

  static double computeCurrentCash({
    required double openingCash,
    required double totalCashIn,
    required double totalCashOut,
  }) {
    return openingCash + totalCashIn - totalCashOut;
  }

  static MonthlyMemberAccount buildMonthlyMemberAccount({
    required String id,
    required String monthlyAccountId,
    required MemberCalc calc,
  }) {
    return MonthlyMemberAccount(
      id: id,
      monthlyAccountId: monthlyAccountId,
      memberId: calc.memberId,
      memberName: calc.memberName,
      totalMeal: calc.totalMeal,
      mealCost: calc.mealCost,
      totalPaid: calc.totalPaid,
      due: calc.due,
      advance: calc.advance,
    );
  }

  static DashboardSummary buildSummary({
    required List<Member> activeMembers,
    required double todayTotalMeal,
    required double monthTotalMeal,
    required double totalExpense,
    required double totalCollection,
    required double openingCash,
    required double totalCashIn,
    required double totalCashOut,
    required List<MemberCalc> memberCalcs,
  }) {
    final mealRate = computeMealRate(totalExpense, monthTotalMeal);
    final currentCash = computeCurrentCash(
      openingCash: openingCash,
      totalCashIn: totalCashIn,
      totalCashOut: totalCashOut,
    );
    double totalDue = 0;
    double totalAdvance = 0;
    for (final c in memberCalcs) {
      totalDue += c.due;
      totalAdvance += c.advance;
    }
    return DashboardSummary(
      activeMembers: activeMembers.length,
      todayTotalMeal: todayTotalMeal,
      monthTotalMeal: monthTotalMeal,
      mealRate: mealRate,
      totalCollection: totalCollection,
      totalExpense: totalExpense,
      openingCash: openingCash,
      currentCash: currentCash,
      totalCashIn: totalCashIn,
      totalCashOut: totalCashOut,
      totalDue: totalDue,
      totalAdvance: totalAdvance,
      memberCalcs: memberCalcs,
    );
  }

  static MonthlyAccount snapshotAccount({
    required String id,
    required int month,
    required int year,
    required double totalMeal,
    required double totalExpense,
    required double totalCollection,
    required double openingCash,
    required double totalCashIn,
    required double totalCashOut,
    required List<MemberCalc> memberCalcs,
    String status = 'active',
  }) {
    final mealRate = computeMealRate(totalExpense, totalMeal);
    return MonthlyAccount(
      id: id,
      month: month,
      year: year,
      totalMeal: totalMeal,
      totalExpense: totalExpense,
      mealRate: mealRate,
      totalCollection: totalCollection,
      openingCash: openingCash,
      closingCash: computeCurrentCash(
        openingCash: openingCash,
        totalCashIn: totalCashIn,
        totalCashOut: totalCashOut,
      ),
      totalCashIn: totalCashIn,
      totalCashOut: totalCashOut,
      status: status,
      closedAt: status == 'closed' ? DateTime.now() : null,
    );
  }
}