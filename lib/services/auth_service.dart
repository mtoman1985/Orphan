import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'sqlite_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    // Check for session timeout every minute
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTimeout();
    });
  }

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool _isInit = false;
  Timer? _sessionTimer;

  void _startSessionTimer() {
    if (_sessionTimer?.isActive ?? false) return;
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkTimeout();
    });
  }

  Future<void> _checkTimeout() async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final loginTimeStr = prefs.getString('auth_login_time');

    if (loginTimeStr != null) {
      final loginTime = DateTime.parse(loginTimeStr);
      if (DateTime.now().difference(loginTime).inHours >= 1) {
        debugPrint('Session expired automatically');
        await logout();
      }
    }
  }

  Future<void> init({bool restoreSession = true}) async {
    if (_isInit) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!restoreSession) {
        await prefs.remove('auth_user');
        await prefs.remove('auth_login_time');
        _currentUser = null;
        return;
      }

      final userJson = prefs.getString('auth_user');
      final loginTimeStr = prefs.getString('auth_login_time');

      if (userJson != null && loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        final now = DateTime.now();

        // Check if 1 hour has passed
        if (now.difference(loginTime).inHours >= 1) {
          debugPrint('Session expired (1 hour limit)');
          await logout();
        } else {
          _currentUser = AppUser.fromJson(json.decode(userJson));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    } finally {
      _isInit = true;
    }
  }

  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String username, String password) async {
    try {
      // 1. Try DB login
      final user = await SqliteService().getUserByUsername(username);
      if (user != null && user.password == password && user.isActive) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_user', json.encode(user.toJson()));
        await prefs.setString(
          'auth_login_time',
          DateTime.now().toIso8601String(),
        );
        _startSessionTimer();
        notifyListeners();
        return true;
      }

      // 2. Emergency Fallback for default admin
      if (username == 'admin' && password == '0599@@') {
        _currentUser = AppUser(
          id: 'admin_1',
          username: 'admin',
          fullName: 'المدير العام (احتياطي)',
          password: '0599@@',
          role: 'admin',
          permissions: [],
          createdAt: DateTime.now(),
          isActive: true,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_user', json.encode(_currentUser!.toJson()));
        await prefs.setString(
          'auth_login_time',
          DateTime.now().toIso8601String(),
        );
        _startSessionTimer();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user');
    await prefs.remove('auth_login_time');
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    return _currentUser!.hasPermission(permission);
  }

  bool get isAdmin => _currentUser?.role == 'admin';
}
