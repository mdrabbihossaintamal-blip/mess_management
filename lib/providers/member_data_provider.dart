import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/meal.dart';
import '../models/member.dart';
import '../models/mess_settings.dart';
import '../models/payment.dart';
import '../services/firestore_service.dart';
import '../services/mess_calculator.dart';
import '../utils/app_utils.dart';

class MemberDataProvider extends ChangeNotifier {
  final FirestoreService _service;
  final String memberId;

  Member? _member;
  List<Meal> _meals = [];
  List<Payment> _payments = [];
  MessSettings? _settings;
  DashboardSummary? _summary;
  List<Expense> _monthExpenses = [];
  bool _loading = false;

  MemberDataProvider(this._service, this.memberId) {
    load();
  }

  Member? get member => _member;
  List<Meal> get meals => _meals;
  List<Payment> get payments => _payments;
  MessSettings? get settings => _settings;
  DashboardSummary? get summary => _summary;
  List<Expense> get monthExpenses => _monthExpenses;
  bool get isLoading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _member = _service.memberForMemberView(memberId);
      _settings = await _service.getSettings();
      final start = AppUtils.monthStart(DateTime.now());
      final end = AppUtils.monthEnd(DateTime.now());
      _meals = await _service.getMeals(
        memberId: memberId,
        from: start,
        to: end,
      );
      _payments = await _service.getPayments(
        memberId: memberId,
        from: start,
        to: end,
      );
      _monthExpenses = await _service.getExpenses(from: start, to: end);
      _summary = await _service.computeMemberSummary(
        memberId: memberId,
        month: DateTime.now(),
        today: DateTime.now(),
      );
    } catch (e) {
      debugPrint('MemberDataProvider load error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  double get monthMealTotal =>
      _meals.fold(0, (s, m) => s + m.totalMeal);

  double get monthMealCost {
    final rate = _summary?.mealRate ?? 0;
    return monthMealTotal * rate;
  }

  double get monthPaid =>
      _payments.fold(0, (s, p) => s + p.amount);

  double get monthDue {
    final cost = monthMealCost;
    final paid = monthPaid;
    return cost > paid ? cost - paid : 0;
  }

  double get monthAdvance {
    final cost = monthMealCost;
    final paid = monthPaid;
    return paid > cost ? paid - cost : 0;
  }

  List<Meal> get mealsForToday {
    final today = DateTime.now();
    return _meals
        .where((m) => AppUtils.isSameDay(m.date, today))
        .toList();
  }
}