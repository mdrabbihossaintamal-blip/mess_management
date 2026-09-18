import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/monthly_account.dart';
import '../models/monthly_member_account.dart';
import '../utils/app_utils.dart';

class ReportService {
  static double _mealRate = 0;

  static String _csvEscape(String s) =>
      '"${s.replaceAll('"', '""')}"';

  static Future<String> buildMonthlyReportCsv({
    required MonthlyAccount account,
    required List<MonthlyMemberAccount> members,
  }) async {
    final b = StringBuffer();
    b.writeln('Mess Meal Management Report');
    b.writeln('Month,${account.monthLabel}');
    b.writeln('Status,${account.status}');
    b.writeln('');
    b.writeln('Summary');
    b.writeln('Total Members,${members.length}');
    b.writeln('Total Meal,${AppUtils.formatAmount(account.totalMeal)}');
    b.writeln('Total Expense,${AppUtils.formatAmount(account.totalExpense)}');
    b.writeln('Meal Rate,${AppUtils.formatAmount(account.mealRate)}');
    b.writeln('Total Collection,${AppUtils.formatAmount(account.totalCollection)}');
    b.writeln('Opening Cash,${AppUtils.formatAmount(account.openingCash)}');
    b.writeln('Total Cash In,${AppUtils.formatAmount(account.totalCashIn)}');
    b.writeln('Total Cash Out,${AppUtils.formatAmount(account.totalCashOut)}');
    b.writeln('Closing Cash,${AppUtils.formatAmount(account.closingCash)}');
    b.writeln('');
    b.writeln('Member Accounts');
    b.writeln('Name,Total Meal,Meal Cost,Total Paid,Due,Advance');
    for (final m in members) {
      b.writeln(
          '${_csvEscape(m.memberName)},${AppUtils.formatAmount(m.totalMeal)},'
          '${AppUtils.formatAmount(m.mealCost)},${AppUtils.formatAmount(m.totalPaid)},'
          '${AppUtils.formatAmount(m.due)},${AppUtils.formatAmount(m.advance)}');
    }
    return b.toString();
  }

  static Future<String> buildDailyReportCsv({
    required DateTime date,
    required List<Map<String, dynamic>> rows,
  }) async {
    final b = StringBuffer();
    b.writeln('Daily Report - ${AppUtils.formatDate(date)}');
    b.writeln('');
    b.writeln('Name,Breakfast,Lunch,Dinner,Total Meal');
    for (final row in rows) {
      b.writeln(
          '${_csvEscape(row['name'] as String)},'
          '${_fmt(row['breakfast'])},${_fmt(row['lunch'])},'
          '${_fmt(row['dinner'])},${_fmt(row['total'])}');
    }
    return b.toString();
  }

  static String _fmt(dynamic v) =>
      AppUtils.formatAmount((v ?? 0).toDouble());

  static Future<String> buildExpenseReportCsv({
    required List<Map<String, dynamic>> rows,
  }) async {
    final b = StringBuffer();
    b.writeln('Expense Report');
    b.writeln('');
    b.writeln('Date,Category,Description,Amount,Paid By');
    for (final row in rows) {
      b.writeln(
          '${_csvEscape(AppUtils.formatDate(row['date'] as DateTime))},'
          '${_csvEscape(row['category'] as String)},'
          '${_csvEscape(row['description'] as String)} ,'
          '${AppUtils.formatAmount((row['amount'] as num).toDouble())},'
          '${_csvEscape(row['paidBy'] as String)}');
    }
    return b.toString();
  }

  static Future<String> buildPaymentReportCsv({
    required List<Map<String, dynamic>> rows,
  }) async {
    final b = StringBuffer();
    b.writeln('Payment Report');
    b.writeln('');
    b.writeln('Date,Member,Amount,Method,Note');
    for (final row in rows) {
      b.writeln(
          '${_csvEscape(AppUtils.formatDate(row['date'] as DateTime))},'
          '${_csvEscape(row['member'] as String)},'
          '${AppUtils.formatAmount((row['amount'] as num).toDouble())},'
          '${_csvEscape(row['method'] as String)},'
          '${_csvEscape(row['note'] as String)}');
    }
    return b.toString();
  }

  static Future<Directory> _getDocsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final sub = Directory('${dir.path}/mess_reports');
    if (!await sub.exists()) await sub.create(recursive: true);
    return sub;
  }

  static Future<String> _writeCsv(String filename, String content) async {
    final dir = await _getDocsDir();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    return file.path;
  }

  static Future<String> exportCsv({
    required String filename,
    required String content,
    bool share = false,
  }) async {
    final path = await _writeCsv(filename, content);
    if (share) {
      await Share.shareXFiles([XFile(path)],
          text: 'Mess Management Report - $filename');
    }
    return path;
  }

  static Future<String> exportMonthlyReport({
    required MonthlyAccount account,
    required List<MonthlyMemberAccount> members,
  }) async {
    final csv = await buildMonthlyReportCsv(account: account, members: members);
    return exportCsv(
      filename: 'monthly_report_${account.year}-${account.month}.csv',
      content: csv,
      share: true,
    );
  }

  static void setMealRate(double rate) {
    _mealRate = rate;
  }

  static double get mealRate => _mealRate;
}