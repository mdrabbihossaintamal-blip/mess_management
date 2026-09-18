import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class AppUtils {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password + 'mess_salt_2026');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  static String formatTaka(double amount, {int decimals = 2}) {
    final format = NumberFormat('#,##0.${'0' * decimals}', 'en_US');
    final formatted = format.format(amount);
    if (decimals == 0) {
      return '৳$formatted';
    }
    return '৳$formatted';
  }

  static String formatAmount(double amount) {
    final format = NumberFormat('#,##0.00', 'en_US');
    return format.format(amount);
  }

  static String formatDate(DateTime date) {
    final format = DateFormat('dd MMM yyyy');
    return format.format(date);
  }

  static String formatDateShort(DateTime date) {
    final format = DateFormat('dd/MM/yyyy');
    return format.format(date);
  }

  static String formatDateTime(DateTime date) {
    final format = DateFormat('dd MMM yyyy, h:mm a');
    return format.format(date);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String monthKey(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    return '${date.year}-$mm';
  }

  static String monthBangla(DateTime date) {
    const months = {
      1: 'জানুয়ারি', 2: 'ফেব্রুয়ারি', 3: 'মার্চ',
      4: 'এপ্রিল', 5: 'মে', 6: 'জুন',
      7: 'জুলাই', 8: 'আগস্ট', 9: 'সেপ্টেম্বর',
      10: 'অক্টোবর', 11: 'নভেম্বর', 12: 'ডিসেম্বর',
    };
    return months[date.month] ?? '';
  }

  static String monthEnglish(DateTime date) {
    const months = {
      1: 'January', 2: 'February', 3: 'March',
      4: 'April', 5: 'May', 6: 'June',
      7: 'July', 8: 'August', 9: 'September',
      10: 'October', 11: 'November', 12: 'December',
    };
    return months[date.month] ?? '';
  }

  static DateTime monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  static DateTime monthEnd(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  static double roundTo(double value, {int places = 2}) {
    final mod = _pow10(places).toDouble();
    return (value * mod).roundToDouble() / mod;
  }

  static int _pow10(int n) {
    int result = 1;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  static String banglaDigit(String text) {
    const bd = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var result = text;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(en[i], bd[i]);
    }
    return result;
  }
}