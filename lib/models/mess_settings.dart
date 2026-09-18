import 'package:cloud_firestore/cloud_firestore.dart';

class MessSettings {
  final String messId;
  final String messName;
  final double defaultBreakfast;
  final double defaultLunch;
  final double defaultDinner;
  final double openingCash;
  final bool notificationsEnabled;
  final DateTime? createdAt;

  MessSettings({
    required this.messId,
    required this.messName,
    this.defaultBreakfast = 0.5,
    this.defaultLunch = 1,
    this.defaultDinner = 1,
    this.openingCash = 0,
    this.notificationsEnabled = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'messId': messId,
        'messName': messName,
        'defaultBreakfast': defaultBreakfast,
        'defaultLunch': defaultLunch,
        'defaultDinner': defaultDinner,
        'openingCash': openingCash,
        'notificationsEnabled': notificationsEnabled,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      };

  factory MessSettings.fromMap(Map<String, dynamic> map) => MessSettings(
        messId: map['messId'] ?? '',
        messName: map['messName'] ?? 'My Mess',
        defaultBreakfast: (map['defaultBreakfast'] ?? 0.5).toDouble(),
        defaultLunch: (map['defaultLunch'] ?? 1).toDouble(),
        defaultDinner: (map['defaultDinner'] ?? 1).toDouble(),
        openingCash: (map['openingCash'] ?? 0).toDouble(),
        notificationsEnabled: map['notificationsEnabled'] ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}