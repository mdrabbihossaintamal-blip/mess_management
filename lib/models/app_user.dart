import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String username;
  final String passwordHash;
  final String role; // 'admin' or 'member'
  final String status; // 'active' or 'inactive'
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    required this.username,
    required this.passwordHash,
    required this.role,
    this.status = 'active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'username': username,
        'passwordHash': passwordHash,
        'role': role,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'] ?? '',
        username: map['username'] ?? '',
        passwordHash: map['passwordHash'] ?? '',
        role: map['role'] ?? 'member',
        status: map['status'] ?? 'active',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? username,
    String? passwordHash,
    String? role,
    String? status,
    DateTime? createdAt,
  }) =>
      AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}
