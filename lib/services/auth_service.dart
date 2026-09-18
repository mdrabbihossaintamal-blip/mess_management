import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../utils/app_utils.dart';

class AuthService {
  const AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Resolve a username or email to the Firebase Auth email used for sign-in.
  /// Username lookup goes through the public `lookup` collection.
  Future<String> resolveEmailForLogin(String identifier) async {
    final id = identifier.trim().toLowerCase();
    if (id.contains('@')) return id;
    final doc = await _db.collection('lookup').doc(id).get();
    if (!doc.exists || !doc.data()!.containsKey('email')) {
      throw Exception('ব্যবহারকারী পাওয়া যায়নি: $identifier');
    }
    return doc.data()!['email'] as String;
  }

  String _adminSessionPassword = '';

  Future<AppUser> signIn({
    required String identifier,
    required String password,
  }) async {
    final email = await resolveEmailForLogin(identifier);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final doc =
          await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        throw Exception('অ্যাকাউন্ট তথ্য পাওয়া যায়নি');
      }
      final user = AppUser.fromMap(doc.data()!);
      if (user.status == 'inactive') {
        await _auth.signOut();
        throw Exception('এই অ্যাকাউন্টটি নিষ্ক্রিয় আছে');
      }
      if (user.role == 'admin') {
        _adminSessionPassword = password;
      }
      _lastUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') throw Exception('ভুল পাসওয়ার্ড');
      if (e.code == 'invalid-credential') throw Exception('ভুল ইউজারনেম বা পাসওয়ার্ড');
      if (e.code == 'too-many-requests') throw Exception('অনেকবার ভুল চেষ্টা হয়েছে, পরে আবার চেষ্টা করুন');
      if (e.code == 'network-request-failed') throw Exception('ইন্টারনেট সংযোগ নেই');
      throw Exception('লগইন ব্যর্থ: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Sign in and refresh the Firestore profile (ensures fresh data).
  Future<AppUser> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('লগইন করা নেই');
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) throw Exception('অ্যাকাউন্ট তথ্য পাওয়া যায়নি');
    return AppUser.fromMap(doc.data()!);
  }

  AppUser? get signedInUser => _auth.currentUser != null ? _lastUser : null;

  AppUser? _lastUser;

  Future<void> setLastUser(AppUser user) async {
    _lastUser = user;
  }

  String get uid => _auth.currentUser?.uid ?? '';

  Future<void> signOut() async {
    _lastUser = null;
    await _auth.signOut();
  }

  /// Create a full new user (admin or member) with a Firebase Auth account.
  /// Passwords are never stored in plain text inside Firestore.
  /// Returns the created AppUser.
  ///
  /// [adminReauth] - set false to skip re-authenticating the currently
  /// signed-in admin (used during first-time setup when one is the new user).
  Future<AppUser> createUser({
    required String name,
    required String phone,
    required String email,
    required String username,
    required String password,
    required String role,
    String status = 'active',
    bool forceCreate = true,
  }) async {
    final normalized = username.trim().toLowerCase();
    final fbEmail = email.trim().isNotEmpty
        ? email.trim()
        : '$normalized@mess.local';

    final current = _auth.currentUser;
    final isCreatingSelf = (forceCreate == false) ||
        current == null ||
        (current.email ?? '') == fbEmail;
    // Capture admin credential so we can restore the admin session after
    // the unavoidable session switch that createUserWithEmailAndPassword
    // triggers (the newly created user becomes the current user).
    final adminEmail = (!isCreatingSelf && current != null) ? current.email : null;
    final adminPassword = _adminSessionPassword;

    String newUid;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: fbEmail,
        password: password,
      );
      newUid = cred.user!.uid;
    } catch (e) {
      throw Exception('অ্যাকাউন্ট তৈরি ব্যর্থ হয়েছে। মনে রাখবেন: প্রতিটি '
          'ইউজারনেম/ইমেইল অনন্য হতে হবে। (${e is FirebaseAuthException ? e.message : e})');
    }

    final hashed = AppUtils.hashPassword(password);
    _lastUser = null;

    try {
      await _db.collection('users').doc(newUid).set({
        'id': newUid,
        'name': name,
        'phone': phone,
        'email': fbEmail,
        'username': normalized,
        'passwordHash': hashed,
        'role': role,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('lookup').doc(normalized).set({
        'uid': newUid,
        'role': role,
        'name': name,
        'email': fbEmail,
      });
    } catch (e) {
      await _auth.signOut();
      throw Exception('ডেটা সংরক্ষণ ব্যর্থ হয়েছে, আবার চেষ্টা করুন');
    }

    // Restore admin session after creating another user's account: the
    // createUserWithEmailAndPassword call switched the current user to the
    // newly created user, so we sign back in as the admin.
    if (!isCreatingSelf && adminEmail != null && adminPassword.isNotEmpty) {
      try {
        await _auth.signInWithEmailAndPassword(
            email: adminEmail, password: adminPassword);
      } catch (_) {
        _lastUser = null;
      }
    }
    return AppUser.fromMap({
      'id': newUid,
      'name': name,
      'phone': phone,
      'email': fbEmail,
      'username': normalized,
      'passwordHash': hashed,
      'role': role,
      'status': status,
    });
  }

  Future<AppUser> _reauthenticateAdminForMember({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return refreshUserById(cred.user!.uid);
  }

  /// Update a member's credential (change username and/or password/PIN).
  /// Returns updated AppUser.
  Future<AppUser> updateCredentials({
    required String uid,
    required String name,
    required String phone,
    required String email,
    required String username,
    String? newPassword,
  }) async {
    final normalized = username.trim().toLowerCase();
    final fbEmail = email.trim().isNotEmpty ? email.trim() : '$normalized@mess.local';

    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) throw Exception('ব্যবহারকারী পাওয়া যায়নি');

    final data = Map<String, dynamic>.from(userDoc.data()!);
    data['name'] = name;
    data['phone'] = phone;
    data['email'] = fbEmail;
    data['username'] = normalized;
    if (newPassword != null && newPassword.isNotEmpty) {
      data['passwordHash'] = AppUtils.hashPassword(newPassword);
    }
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    await _db.collection('lookup').doc(normalized).set({
      'uid': uid,
      'role': data['role'],
      'name': name,
      'email': fbEmail,
    });
    return AppUser.fromMap(data);
  }

  Future<void> setStatus({required String uid, required String status}) async {
    await _db.collection('users').doc(uid).update({'status': status});
  }

  Future<AppUser> refreshUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('অ্যাকাউন্ট তথ্য পাওয়া যায়নি');
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> sendPasswordReset(String identifier) async {
    final email = await resolveEmailForLogin(identifier);
    await _auth.sendPasswordResetEmail(email: email);
  }
}