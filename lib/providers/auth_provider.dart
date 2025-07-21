import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perpus_app/services/library_api_service.dart';

class AuthProvider with ChangeNotifier {
  final LibraryApiService _apiService = LibraryApiService();

  bool _isLoggedIn = false;
  String _userName = '';
  String _userRole = '';
  String _userEmail = '';
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userRole => _userRole;
  String get userEmail => _userEmail;
  bool get isLoading => _isLoading;

  bool get isAdmin => _userRole.toLowerCase() == 'admin';
  bool get isMember => _userRole.toLowerCase() == 'member';

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        _isLoggedIn = true;
        _userName = prefs.getString('user_name') ?? '';
        _userRole = prefs.getString('user_role') ?? 'member';
        _userEmail = prefs.getString('user_email') ?? '';
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {

      }
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.login(username, password);

      if (success) {
        await _loadAuthData();
        _isLoggedIn = true;
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {

      }
      return false;
    }
  }

  Future<bool> register(Map<String, String> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.register(userData);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {

      }
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
      _isLoggedIn = false;
      _userName = '';
      _userRole = '';
      _userEmail = '';
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {

      }
    }
  }

  // Check if token is still valid
  Future<bool> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        await logout();
        return false;
      }

      // If we have a token, assume it's valid for now
      // You could add an API call to verify the token here
      return true;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // Update user information
  Future<void> updateUserInfo(String name, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);

      _userName = name;
      _userEmail = email;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {

      }
    }
  }
}
