import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AuthProvider(this._authService);

  AppUser? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isMember => _user?.role == 'member';

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signIn(
        identifier: identifier,
        password: password,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      _user = await _authService.refreshCurrentUser();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> signOut() async {
    _user = null;
    await _authService.signOut();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}