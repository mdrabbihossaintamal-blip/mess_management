import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  bool get enabled => _initialized;

  Future<void> show({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mess_notifications',
        'Mess Management',
        channelDescription: 'Mess meal and payment notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  Future<void> showMealReminder(DateTime date) async {
    await show(
      id: 1,
      title: 'মেস ম্যানেজমেন্ট',
      body: 'আজকের মিল এন্ট্রি করুন (${date.day}/${date.month})',
    );
  }

  Future<void> showPaymentReminder(String memberName, double due) async {
    await show(
      id: 2,
      title: 'পেমেন্ট রিমাইন্ডার',
      body: '$memberName এর বকেয়া: ৳${due.toStringAsFixed(2)}',
    );
  }

  Future<void> showDueNotification(int memberCount) async {
    await show(
      id: 3,
      title: 'বকেয়া আপডেট',
      body: '$memberCount জন সদস্যের বকেয়া আছে',
    );
  }

  Future<void> showMonthlyClosingReminder() async {
    await show(
      id: 4,
      title: 'মাসিক ক্লোজিং',
      body: 'মাস শেষ হতে চলেছে, অ্যাকাউন্ট ক্লোজ করুন',
    );
  }
}