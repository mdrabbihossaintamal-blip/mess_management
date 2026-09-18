import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/expense.dart';
import '../models/meal.dart';
import '../models/member.dart';
import '../models/mess_settings.dart';
import '../models/payment.dart';
import '../models/cash_transaction.dart';
import '../models/monthly_account.dart';
import '../models/monthly_member_account.dart';
import '../services/firestore_service.dart';
import '../services/mess_calculator.dart';
import '../utils/app_utils.dart';

class DataProvider extends ChangeNotifier {
  final FirestoreService _service;

  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  List<Member> _members = [];
  List<Meal> _monthMeals = [];
  List<Expense> _monthExpenses = [];
  List<Payment> _monthPayments = [];
  List<CashTransaction> _cashTransactions = [];
  List<MonthlyAccount> _monthlyAccounts = [];
  MessSettings? _settings;
  MonthlyAccount? _activeAccount;

  DashboardSummary? _summary;
  bool _loading = true;
  String? _error;
  List<StreamSubscription<dynamic>> _subs = [];
  bool _initialized = false;

  DataProvider(this._service);

  bool get isInitialized => _initialized;

  Future<void> init() async {
    await _load();
  }

  DateTime get selectedMonth => _selectedMonth;
  DateTime get selectedDate => _selectedDate;
  List<Member> get members => _members;
  List<Meal> get monthMeals => _monthMeals;
  List<Expense> get monthExpenses => _monthExpenses;
  List<Payment> get monthPayments => _monthPayments;
  List<CashTransaction> get cashTransactions => _cashTransactions;
  List<MonthlyAccount> get monthlyAccounts => _monthlyAccounts;
  MessSettings? get settings => _settings;
  MonthlyAccount? get activeAccount => _activeAccount;
  DashboardSummary? get summary => _summary;
  bool get isLoading => _loading;
  String? get error => _error;

  List<Member> get activeMembers =>
      _members.where((m) => m.status == 'active').toList();

  Member? memberById(String id) {
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Member? memberByUserId(String userId) => memberById(userId);

  Future<void> _load() async {
    _loading = true;
    notifyListeners();
    try {
      await _loadCore();
      // refresh summary in background
      unawaited(_refreshSummary());
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadCore();
    await _refreshSummary();
    notifyListeners();
  }

  Future<void> _loadCore() async {
    try {
      _settings = await _service.getSettings();
    } catch (_) {}
    try {
      _members = await _service.getMembers(includeInactive: true);
    } catch (_) {}
    try {
      _monthlyAccounts = await _service.getAllMonthlyAccounts();
    } catch (_) {}
    await _reloadMonthScoped();
  }

  Future<void> _reloadMonthScoped() async {
    final start = AppUtils.monthStart(_selectedMonth);
    final end = AppUtils.monthEnd(_selectedMonth);
    try {
      _monthMeals =
          await _service.getMeals(from: start, to: end);
      _monthExpenses =
          await _service.getExpenses(from: start, to: end);
      _monthPayments =
          await _service.getPayments(from: start, to: end);
      _cashTransactions = await _service.getCashTransactions();
    } catch (_) {}
    try {
      _activeAccount =
          await _service.getMonthlyAccount(_selectedMonth.month, _selectedMonth.year);
    } catch (_) {}
  }

  Future<void> _refreshSummary() async {
    try {
      _summary = await _service.computeSummary(
        month: _selectedMonth,
        today: _selectedDate,
      );
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _reloadMonthScoped().then((_) => _refreshSummary());
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    if (date.month != _selectedMonth.month || date.year != _selectedMonth.year) {
      _selectedMonth = AppUtils.monthStart(date);
      _reloadMonthScoped().then((_) => _refreshSummary());
    } else {
      notifyListeners();
      _refreshSummary();
    }
  }

  // ---------- Members ----------
  Future<void> addMember({
    required String userId,
    required String name,
    required String phone,
    DateTime? joinDate,
  }) async {
    await _service.addMember(
      userId: userId,
      name: name,
      phone: phone,
      joinDate: joinDate,
    );
    await refresh();
  }

  Future<void> updateMember({
    required String userId,
    String? name,
    String? phone,
    String? status,
  }) async {
    await _service.updateMember(
      userId: userId,
      name: name,
      phone: phone,
      status: status,
    );
    await refresh();
  }

  Future<void> toggleMemberStatus(String userId, String status) async {
    await _service.toggleMemberStatus(userId, status);
    await refresh();
  }

  // ---------- Meals ----------
  Future<void> updateMealsForDate(DateTime date, Map<String, Meal> meals) async {
    await _service.saveMeals(meals);
    await refresh();
  }

  Future<void> deleteMeal(String mealId) async {
    await _service.deleteMeal(mealId);
    await refresh();
  }

  // ---------- Expenses ----------
  Future<void> addExpense({
    required DateTime date,
    required String category,
    required String description,
    required double amount,
    required String paidBy,
    String note = '',
  }) async {
    await _service.addExpense(
      date: date,
      category: category,
      description: description,
      amount: amount,
      paidBy: paidBy,
      note: note,
    );
    await refresh();
  }

  Future<void> updateExpense(Expense expense) async {
    await _service.updateExpense(expense);
    await refresh();
  }

  Future<void> deleteExpense(String expenseId) async {
    await _service.deleteExpense(expenseId);
    await refresh();
  }

  // ---------- Payments ----------
  Future<void> addPayment({
    required String memberId,
    required DateTime date,
    required double amount,
    required String method,
    String note = '',
  }) async {
    await _service.addPayment(
      memberId: memberId,
      date: date,
      amount: amount,
      method: method,
      note: note,
    );
    await refresh();
  }

  Future<void> updatePayment(Payment payment) async {
    await _service.updatePayment(payment);
    await refresh();
  }

  Future<void> deletePayment(String paymentId) async {
    await _service.deletePayment(paymentId);
    await refresh();
  }

  // ---------- Cash ----------
  Future<void> addCashTransaction({
    required String type,
    required String category,
    required double amount,
    required DateTime date,
    String description = '',
  }) async {
    await _service.addCashTransaction(
      type: type,
      category: category,
      amount: amount,
      date: date,
      description: description,
    );
    await refresh();
  }

  // ---------- Monthly ----------
  Future<void> closeMonth() async {
    await _service.closeMonth(_selectedMonth.month, _selectedMonth.year);
    await refresh();
  }

  Future<void> startNewMonth(int month, int year) async {
    await _service.startNewMonth(month, year);
    await refresh();
  }

  Future<void> reopenMonth(int month, int year) async {
    await _service.reopenMonth(month, year);
    await refresh();
  }

  Future<List<MonthlyMemberAccount>> getClosedMemberAccounts() async {
    final id = '${_selectedMonth.year}-${_selectedMonth.month}';
    return _service.getMonthlyMemberAccounts(id);
  }

  Future<MonthlyAccount?> getActiveAccountForReport(DateTime month) async {
    return _service.getMonthlyAccount(month.month, month.year);
  }

  // ---------- Settings ----------
  Future<void> updateSettings({
    String? messName,
    double? defaultBreakfast,
    double? defaultLunch,
    double? defaultDinner,
    bool? notificationsEnabled,
  }) async {
    await _service.updateSettings(
      messName: messName,
      defaultBreakfast: defaultBreakfast,
      defaultLunch: defaultLunch,
      defaultDinner: defaultDinner,
      notificationsEnabled: notificationsEnabled,
    );
    await _loadCore();
    notifyListeners();
  }

  void disposeMe() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}