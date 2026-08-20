import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../services/token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _loading = false;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get loading => _loading;

  /// Call on app start: checks for a stored token and, if present, tries to
  /// load the current user's profile.
  Future<void> tryAutoLogin() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _authService.fetchMe();
      _status = AuthStatus.authenticated;
      await PushNotificationService.syncTokenWithBackend();
    } catch (_) {
      await TokenStorage.clear();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.login(username, password);
      _status = AuthStatus.authenticated;
      await PushNotificationService.syncTokenWithBackend();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> registerCustomer({
    required String username,
    required String password,
    required String passwordConfirm,
    required String phoneNumber,
    String? email,
    String? firstName,
    String? lastName,
    String? defaultDeliveryAddress,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.registerCustomer(
        username: username,
        password: password,
        passwordConfirm: passwordConfirm,
        phoneNumber: phoneNumber,
        email: email,
        firstName: firstName,
        lastName: lastName,
        defaultDeliveryAddress: defaultDeliveryAddress,
      );
      _status = AuthStatus.authenticated;
      await PushNotificationService.syncTokenWithBackend();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Re-fetches the current user's profile from the backend. Call this after
  /// an action that may have changed something the profile shows (e.g. the
  /// backend auto-updates default_delivery_address after a new order).
  Future<void> refreshUser() async {
    try {
      _user = await _authService.fetchMe();
      notifyListeners();
    } catch (_) {
      // Non-fatal: keep showing the last known profile if this fails.
    }
  }
}
