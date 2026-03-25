import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username != null) {
      final user = await _db.getUserByUsername(username); // 🔥 lấy lại từ DB

      if (user != null) {
        _currentUser = user; // ✅ có password luôn
        notifyListeners();
      }
    }
  }

  Future<bool> register(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final existing = await _db.getUserByUsername(username);
      if (existing != null) {
        _errorMessage = 'Username already exists.';
        _setLoading(false);
        return false;
      }

      final user = User(username: username, password: password);
      final id = await _db.insertUser(user);
      _currentUser = user.copyWith(id: id);
      await _saveSession(_currentUser!);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _db.loginUser(username, password);
      if (user == null) {
        _errorMessage = 'Invalid username or password.';
        _setLoading(false);
        return false;
      }
      _currentUser = user;
      await _saveSession(user);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', user.id!);
    await prefs.setString('username', user.username);
  }
  Future<void> updateUser(User user) async {
    await _db.updateUser(user);
    _currentUser = user;
    await _saveSession(user);
    notifyListeners();
  }

  Future<void> changePassword(String newPassword) async {
    if (_currentUser == null) return;

    await _db.updatePassword(_currentUser!.username, newPassword);

    _currentUser =
        _currentUser!.copyWith(password: newPassword);

    notifyListeners();
  }
  Future<User?> getUserByUsername(String username) async {
    return await _db.getUserByUsername(username);
  }
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
