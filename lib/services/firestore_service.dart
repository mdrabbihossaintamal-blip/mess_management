import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/meal.dart';
import '../models/member.dart';
import '../models/mess_settings.dart';
import '../models/monthly_account.dart';
import '../models/monthly_member_account.dart';
import '../models/payment.dart';
import '../models/cash_transaction.dart';
import '../models/app_user.dart';
import '../utils/app_utils.dart';
import 'auth_service.dart';
import 'mess_calculator.dart';

class FirestoreService {
  const FirestoreService(this._auth);

  final AuthService _auth;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  static const String messDocId = 'main';

  /// ------------------- MESS -------------------
  Future<void> createMess(MessSettings settings) async {
    await _db.collection('settings').doc(messDocId).set(settings.toMap());
  }

  Future<MessSettings?> getSettings() async {
    final doc = await _db.collection('settings').doc(messDocId).get();
    if (!doc.exists) return null;
    return MessSettings.fromMap(doc.data()!);
  }

  Future<void> updateSettings({
    String? messName,
    double? defaultBreakfast,
    double? defaultLunch,
    double? defaultDinner,
    bool? notificationsEnabled,
  }) async {
    final data = <String, dynamic>{
      if (messName != null) 'messName': messName,
      if (defaultBreakfast != null) 'defaultBreakfast': defaultBreakfast,
      if (defaultLunch != null) 'defaultLunch': defaultLunch,
      if (defaultDinner != null) 'defaultDinner': defaultDinner,
      if (notificationsEnabled != null)
        'notificationsEnabled': notificationsEnabled,
    };
    await _db.collection('settings').doc(messDocId).update(data);
  }

  /// ------------------- MEMBERS -------------------
  Future<void> addMember({
    required String userId,
    required String name,
    required String phone,
    DateTime? joinDate,
    String status = 'active',
  }) async {
    await _db.collection('members').doc(userId).set({
      'id': userId,
      'userId': userId,
      'name': name,
      'phone': phone,
      'status': status,
      'joinDate': joinDate != null
          ? Timestamp.fromDate(joinDate)
          : FieldValue.serverTimestamp(),
      'currentMonthMeals': 0,
      'currentBalance': 0,
    });
  }

  Future<List<Member>> getMembers({bool includeInactive = true}) async {
    final snap = await _db.collection('members').get();
    final members = snap.docs
        .map((d) => Member.fromMap(d.data()))
        .toList();
    members.sort((a, b) => a.name.compareTo(b.name));
    if (includeInactive) return members;
    return members.where((m) => m.status == 'active').toList();
  }

  Stream<List<Member>> streamMembers() {
    return _db.collection('members').snapshots().map((snap) {
      final members = snap.docs.map((d) => Member.fromMap(d.data())).toList();
      members.sort((a, b) => a.name.compareTo(b.name));
      return members;
    });
  }

  Future<void> updateMember({
    required String userId,
    String? name,
    String? phone,
    String? status,
    DateTime? joinDate,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (status != null) 'status': status,
      if (joinDate != null) 'joinDate': Timestamp.fromDate(joinDate),
    };
    await _db.collection('members').doc(userId).update(data);
  }

  Future<void> toggleMemberStatus(String userId, String status) async {
    await _db.collection('members').doc(userId).update({'status': status});
  }

  Future<void> deleteMember(String userId) async {
    // Soft delete: mark the linked user inactive and remove member snapshot.
    await _db.collection('members').doc(userId).update({'status': 'inactive'});
    // Historical data remains (meals/payments), only user disabled.
  }

  /// ------------------- MEALS -------------------
  Future<void> saveMeals(Map<String, Meal> meals) async {
    final batch = _db.batch();
    for (final meal in meals.values) {
      if (meal.totalMeal <= 0) continue;
      final ref = _db.collection('meals').doc(meal.id);
      if (meal.isDeleted) {
        batch.set(ref, meal.toMap(), SetOptions(merge: true));
      } else {
        batch.set(ref, meal.toMap());
      }
    }
    await batch.commit();
  }

  Future<void> saveMeal(Meal meal) async {
    await _db.collection('meals').doc(meal.id).set(meal.toMap());
  }

  Future<void> updateMeal(Meal meal) async {
    await _db.collection('meals').doc(meal.id).set(
      meal.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteMeal(String mealId) async {
    await _db.collection('meals').doc(mealId).update({'isDeleted': true});
  }

  Future<Meal?> getMealForMemberAndDate({
    required String memberId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _db
        .collection('meals')
        .where('memberId', isEqualTo: memberId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Meal.fromMap(snap.docs.first.data());
  }

  Future<List<Meal>> getMeals({
    DateTime? from,
    DateTime? to,
    String? memberId,
  }) async {
    var query = _db
        .collection('meals')
        .where('isDeleted', isEqualTo: false);
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    final snap = await query.get();
    return snap.docs.map((d) => Meal.fromMap(d.data())).toList();
  }

  Stream<List<Meal>> streamMeals({
    DateTime? from,
    DateTime? to,
    String? memberId,
  }) {
    var query = _db
        .collection('meals')
        .where('isDeleted', isEqualTo: false);
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => Meal.fromMap(d.data())).toList());
  }

  Stream<List<Meal>> streamMealsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('meals')
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) => snap.docs.map((d) => Meal.fromMap(d.data())).toList());
  }

  Future<Map<String, Meal>> getMealsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _db
        .collection('meals')
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    final map = <String, Meal>{};
    for (final d in snap.docs) {
      final m = Meal.fromMap(d.data());
      map[m.memberId] = m;
    }
    return map;
  }

  /// ------------------- EXPENSES -------------------
  Future<void> addExpense({
    required DateTime date,
    required String category,
    required String description,
    required double amount,
    required String paidBy,
    String note = '',
  }) async {
    final id = _uuid.v4();
    final expense = Expense(
      id: id,
      date: date,
      category: category,
      description: description,
      amount: amount,
      paidBy: paidBy,
      note: note,
      createdBy: _auth.uid,
    );
    await _db.collection('expenses').doc(id).set(expense.toMap());
    await _recordCashTransaction(
      type: 'out',
      category: 'expense',
      amount: amount,
      date: date,
      description: '${expense.category} - ${expense.description}',
      reference: id,
    );
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.collection('expenses').doc(expense.id).set(
          expense.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteExpense(String expenseId) async {
    await _db
        .collection('expenses')
        .doc(expenseId)
        .update({'isDeleted': true});
    // Also soft-delete linked cash transaction reference.
    final txn = await _getCashTransactionByReference(expenseId);
    if (txn != null) {
      await _db.collection('cashTransactions').doc(txn.id).update({
        'isDeleted': true,
      });
    }
  }

  Future<List<Expense>> getExpenses({DateTime? from, DateTime? to}) async {
    var query = _db.collection('expenses').where('isDeleted', isEqualTo: false);
    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    final snap = await query.get();
    final list = snap.docs.map((d) => Expense.fromMap(d.data())).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Stream<List<Expense>> streamExpenses(DateTime month) {
    final from = AppUtils.monthStart(month);
    final to = AppUtils.monthEnd(month);
    final endExclusive = to.add(const Duration(days: 1));
    return _db
        .collection('expenses')
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(endExclusive))
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Expense.fromMap(d.data())).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// ------------------- PAYMENTS -------------------
  Future<void> addPayment({
    required String memberId,
    required DateTime date,
    required double amount,
    required String method,
    String note = '',
  }) async {
    final id = _uuid.v4();
    final payment = Payment(
      id: id,
      memberId: memberId,
      date: date,
      amount: amount,
      paymentMethod: method,
      note: note,
      createdBy: _auth.uid,
    );
    await _db.collection('payments').doc(id).set(payment.toMap());
    await _recordCashTransaction(
      type: 'in',
      category: 'payment',
      amount: amount,
      date: date,
      description: 'Payment $method - $memberId',
      reference: id,
    );
  }

  Future<void> updatePayment(Payment payment) async {
    await _db.collection('payments').doc(payment.id).set(
          payment.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deletePayment(String paymentId) async {
    await _db.collection('payments').doc(paymentId).update({'isDeleted': true});
    final txn = await _getCashTransactionByReference(paymentId);
    if (txn != null) {
      await _db.collection('cashTransactions').doc(txn.id).update({
        'isDeleted': true,
      });
    }
  }

  Future<List<Payment>> getPayments({
    DateTime? from,
    DateTime? to,
    String? memberId,
  }) async {
    var query =
        _db.collection('payments').where('isDeleted', isEqualTo: false);
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    final snap = await query.get();
    final list = snap.docs.map((d) => Payment.fromMap(d.data())).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Stream<List<Payment>> streamPayments({
    DateTime? from,
    DateTime? to,
    String? memberId,
  }) {
    var query =
        _db.collection('payments').where('isDeleted', isEqualTo: false);
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return query.snapshots().map((snap) {
      final list =
          snap.docs.map((d) => Payment.fromMap(d.data())).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// ------------------- CASH -------------------
  Future<void> _recordCashTransaction({
    required String type,
    required String category,
    required double amount,
    required DateTime date,
    required String description,
    required String reference,
  }) async {
    final id = _uuid.v4();
    final txn = CashTransaction(
      id: id,
      date: date,
      type: type,
      category: category,
      amount: amount,
      description: description,
      reference: reference,
      createdBy: _auth.uid,
    );
    await _db.collection('cashTransactions').doc(id).set(txn.toMap());
  }

  Future<CashTransaction?> _getCashTransactionByReference(String ref) async {
    final snap = await _db
        .collection('cashTransactions')
        .where('reference', isEqualTo: ref)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return CashTransaction.fromMap(snap.docs.first.data());
  }

  Future<void> addCashTransaction({
    required String type,
    required String category,
    required double amount,
    required DateTime date,
    String description = '',
    String reference = '',
  }) async {
    final id = _uuid.v4();
    final txn = CashTransaction(
      id: id,
      date: date,
      type: type,
      category: category,
      amount: amount,
      description: description,
      reference: reference,
      createdBy: _auth.uid,
    );
    await _db.collection('cashTransactions').doc(id).set(txn.toMap());
  }

  Future<List<CashTransaction>> getCashTransactions({
    DateTime? from,
    DateTime? to,
    bool includeDeleted = false,
  }) async {
    var query = _db.collection('cashTransactions');
    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }
    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    final snap = await query.get();
    final list =
        snap.docs.map((d) => CashTransaction.fromMap(d.data())).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double sumCashIn(List<CashTransaction> txns) =>
      txns.where((t) => t.type == 'in' && !t.isDeleted).fold(
          0, (s, t) => s + t.amount);

  double sumCashOut(List<CashTransaction> txns) =>
      txns.where((t) => t.type == 'out' && !t.isDeleted).fold(
          0, (s, t) => s + t.amount);

  /// ------------------- MONTHLY ACCOUNTS -------------------
  Future<void> saveMonthlyAccount(MonthlyAccount account) async {
    await _db
        .collection('monthlyAccounts')
        .doc('${account.year}-${account.month}')
        .set(account.toMap());
  }

  Future<MonthlyAccount?> getMonthlyAccount(int month, int year) async {
    final doc = await _db
        .collection('monthlyAccounts')
        .doc('$year-$month')
        .get();
    if (!doc.exists) return null;
    return MonthlyAccount.fromMap(doc.data()!);
  }

  Stream<MonthlyAccount?> streamMonthlyAccount(int month, int year) {
    return _db
        .collection('monthlyAccounts')
        .doc('$year-$month')
        .snapshots()
        .map((doc) =>
            doc.exists ? MonthlyAccount.fromMap(doc.data()!) : null);
  }

  Future<List<MonthlyAccount>> getAllMonthlyAccounts() async {
    final snap = await _db.collection('monthlyAccounts').get();
    final list =
        snap.docs.map((d) => MonthlyAccount.fromMap(d.data())).toList();
    list.sort((a, b) {
      final keyA = '${a.year}${a.month.toString().padLeft(2, '0')}';
      final keyB = '${b.year}${b.month.toString().padLeft(2, '0')}';
      return keyB.compareTo(keyA);
    });
    return list;
  }

  Stream<List<MonthlyAccount>> streamAllMonthlyAccounts() {
    return _db.collection('monthlyAccounts').snapshots().map((snap) {
      final list =
          snap.docs.map((d) => MonthlyAccount.fromMap(d.data())).toList();
      list.sort((a, b) {
        final keyA = '${a.year}${a.month.toString().padLeft(2, '0')}';
        final keyB = '${b.year}${b.month.toString().padLeft(2, '0')}';
        return keyB.compareTo(keyA);
      });
      return list;
    });
  }

  Future<void> saveMonthlyMemberAccounts(
    List<MonthlyMemberAccount> accounts,
  ) async {
    final batch = _db.batch();
    for (final a in accounts) {
      batch.set(_db.collection('monthlyMemberAccounts').doc(a.id), a.toMap());
    }
    await batch.commit();
  }

  Future<List<MonthlyMemberAccount>> getMonthlyMemberAccounts(
    String monthlyAccountId,
  ) async {
    final snap = await _db
        .collection('monthlyMemberAccounts')
        .where('monthlyAccountId', isEqualTo: monthlyAccountId)
        .get();
    return snap.docs
        .map((d) => MonthlyMemberAccount.fromMap(d.data()))
        .toList();
  }

  /// ------------------- URLS / EXPORT -------------------
  String collectionName(String name) => name;

  /// ------------------- DASHBOARD SUMMARY -------------------
  Future<DashboardSummary> computeSummary({
    required DateTime month,
    required DateTime today,
  }) async {
    final members = await getMembers(includeInactive: false);
    final settings = await getSettings();
    final openingCash = settings?.openingCash ?? 0;

    final monthStart = AppUtils.monthStart(month);
    final monthEnd = AppUtils.monthEnd(month);

    // Meals for the month
    final monthMeals = await getMeals(from: monthStart, to: monthEnd);
    double monthTotalMeal = 0;
    final memberMeals = <String, double>{};
    for (final meal in monthMeals) {
      monthTotalMeal += meal.totalMeal;
      memberMeals[meal.memberId] =
          (memberMeals[meal.memberId] ?? 0) + meal.totalMeal;
    }

    // Today's meals
    double todayMeal = 0;
    final todays = monthMeals.where((m) => AppUtils.isSameDay(m.date, today));
    for (final meal in todays) {
      todayMeal += meal.totalMeal;
    }

    // Expenses
    final expenses = await getExpenses(from: monthStart, to: monthEnd);
    double totalExpense = 0;
    for (final e in expenses) {
      totalExpense += e.amount;
    }

    // Payments
    final payments = await getPayments(from: monthStart, to: monthEnd);
    double totalCollection = 0;
    final memberPayments = <String, double>{};
    for (final p in payments) {
      totalCollection += p.amount;
      memberPayments[p.memberId] =
          (memberPayments[p.memberId] ?? 0) + p.amount;
    }

    // Cash transactions
    final cashTxns = await getCashTransactions();
    final cashIn = sumCashIn(cashTxns);
    final cashOut = sumCashOut(cashTxns);

    final mealRate =
        MessCalculator.computeMealRate(totalExpense, monthTotalMeal);
    final memberCalcs = MessCalculator.computeMemberAccounts(
      members: members,
      memberMeals: memberMeals,
      memberPayments: memberPayments,
      mealRate: mealRate,
    );

    return MessCalculator.buildSummary(
      activeMembers: members,
      todayTotalMeal: todayMeal,
      monthTotalMeal: monthTotalMeal,
      totalExpense: totalExpense,
      totalCollection: totalCollection,
      openingCash: openingCash,
      totalCashIn: cashIn,
      totalCashOut: cashOut,
      memberCalcs: memberCalcs,
    );
  }

  Future<DashboardSummary?> computeMemberSummary({
    required String memberId,
    required DateTime month,
    required DateTime today,
  }) async {
    final allMembers = await getMembers(includeInactive: false);
    final settings = await getSettings();
    final openingCash = settings?.openingCash ?? 0;
    final monthStart = AppUtils.monthStart(month);
    final monthEnd = AppUtils.monthEnd(month);

    final monthMeals = await getMeals(from: monthStart, to: monthEnd);
    double monthTotalMeal = 0;
    final memberMeals = <String, double>{};
    for (final meal in monthMeals) {
      monthTotalMeal += meal.totalMeal;
      memberMeals[meal.memberId] =
          (memberMeals[meal.memberId] ?? 0) + meal.totalMeal;
    }

    double todayMeal = 0;
    for (final meal in monthMeals) {
      if (AppUtils.isSameDay(meal.date, today)) todayMeal += meal.totalMeal;
    }

    final expenses = await getExpenses(from: monthStart, to: monthEnd);
    double totalExpense = 0;
    for (final e in expenses) {
      totalExpense += e.amount;
    }

    final payments = await getPayments(from: monthStart, to: monthEnd);
    double totalCollection = 0;
    final memberPayments = <String, double>{};
    for (final p in payments) {
      totalCollection += p.amount;
      memberPayments[p.memberId] =
          (memberPayments[p.memberId] ?? 0) + p.amount;
    }

    final cashTxns = await getCashTransactions();
    final cashIn = sumCashIn(cashTxns);
    final cashOut = sumCashOut(cashTxns);
    final mealRate = MessCalculator.computeMealRate(totalExpense, monthTotalMeal);
    final memberCalcs = MessCalculator.computeMemberAccounts(
      members: allMembers,
      memberMeals: memberMeals,
      memberPayments: memberPayments,
      mealRate: mealRate,
    );

    return MessCalculator.buildSummary(
      activeMembers: allMembers,
      todayTotalMeal: todayMeal,
      monthTotalMeal: monthTotalMeal,
      totalExpense: totalExpense,
      totalCollection: totalCollection,
      openingCash: openingCash,
      totalCashIn: cashIn,
      totalCashOut: cashOut,
      memberCalcs: memberCalcs,
    );
  }

  /// ------------------- MONTH CLOSE / OPEN -------------------
  Future<void> closeMonth(int month, int year) async {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    final monthlyAcc = await getMonthlyAccount(month, year);
    if (monthlyAcc == null) {
      throw Exception('এই মাসের অ্যাকাউন্ট পাওয়া যায়নি');
    }

    final members = await getMembers(includeInactive: true);
    final meals = await getMeals(from: monthStart, to: monthEnd);
    final memberMeals = <String, double>{};
    double totalMeal = 0;
    for (final m in meals) {
      totalMeal += m.totalMeal;
      memberMeals[m.memberId] = (memberMeals[m.memberId] ?? 0) + m.totalMeal;
    }

    final payments = await getPayments(from: monthStart, to: monthEnd);
    final memberPayments = <String, double>{};
    double totalCollection = 0;
    for (final p in payments) {
      totalCollection += p.amount;
      memberPayments[p.memberId] =
          (memberPayments[p.memberId] ?? 0) + p.amount;
    }

    final expenses = await getExpenses(from: monthStart, to: monthEnd);
    double totalExpense = 0;
    for (final e in expenses) {
      totalExpense += e.amount;
    }

    final mealRate = MessCalculator.computeMealRate(totalExpense, totalMeal);
    final calcs = MessCalculator.computeMemberAccounts(
      members: members,
      memberMeals: memberMeals,
      memberPayments: memberPayments,
      mealRate: mealRate,
    );

    final cashTxns = await getCashTransactions();
    final cashIn = sumCashIn(cashTxns);
    final cashOut = sumCashOut(cashTxns);
    final closingCash = openingCashFor(monthlyAcc, cashIn, cashOut);

    final closed = MonthlyAccount(
      id: '${year}-$month',
      month: month,
      year: year,
      totalMeal: totalMeal,
      totalExpense: totalExpense,
      mealRate: mealRate,
      totalCollection: totalCollection,
      openingCash: monthlyAcc.openingCash,
      closingCash: closingCash,
      otherIncome: monthlyAcc.otherIncome,
      totalCashIn: cashIn,
      totalCashOut: cashOut,
      status: 'closed',
      closedAt: DateTime.now(),
    );
    await saveMonthlyAccount(closed);

    final memberAccounts = calcs
        .map((c) => MessCalculator.buildMonthlyMemberAccount(
              id: _uuid.v4(),
              monthlyAccountId: '${year}-$month',
              calc: c,
            ))
        .toList();
    await saveMonthlyMemberAccounts(memberAccounts);

    // Start next month with closing cash as new opening.
    final next = DateTime(year, month + 1, 1);
    final nextOpen = await getMonthlyAccount(next.month, next.year);
    if (nextOpen == null) {
      await saveMonthlyAccount(
        MonthlyAccount(
          id: '${next.year}-${next.month}',
          month: next.month,
          year: next.year,
          openingCash: closingCash,
          status: 'active',
        ),
      );
      await _db
          .collection('settings')
          .doc(messDocId)
          .update({'openingCash': closingCash});
    }
  }

  double openingCashFor(MonthlyAccount acc, double cashIn, double cashOut) {
    return acc.openingCash + cashIn - cashOut;
  }

  Future<void> startNewMonth(int month, int year) async {
    final id = '$year-$month';
    final existing = await getMonthlyAccount(month, year);
    if (existing != null) return;
    final settings = await getSettings();
    await saveMonthlyAccount(
      MonthlyAccount(
        id: id,
        month: month,
        year: year,
        openingCash: settings?.openingCash ?? 0,
        status: 'active',
      ),
    );
  }

  Future<void> reopenMonth(int month, int year) async {
    final doc = _db.collection('monthlyAccounts').doc('$year-$month');
    await doc.update({
      'status': 'reopened',
      'closedAt': FieldValue.delete(),
    });
  }

  /// ------------------- AUDIT -------------------
  Future<void> logAudit({
    required String action,
    required String targetType,
    String targetId = '',
    Map<String, dynamic>? changes,
  }) async {
    await _db.collection('auditLogs').add({
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'changes': changes ?? {},
      'by': _auth.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Member? _memberCache;
  Member? _viewMember;

  Member? memberForMemberView(String memberId) {
    // Provide a lightweight snapshot so the view has something to show
    // before Firestore returns; the real object is loaded via stream below.
    if (_viewMember == null || _viewMember!.id != memberId) {
      _viewMember = Member(id: memberId, userId: memberId, name: 'সদস্য', phone: '');
      _refreshMemberSnapshot(memberId);
    }
    return _viewMember;
  }

  Future<void> _refreshMemberSnapshot(String memberId) async {
    try {
      final doc = await _db.collection('members').doc(memberId).get();
      if (doc.exists) {
        _viewMember = Member.fromMap(doc.data()!);
      }
    } catch (_) {}
  }
}