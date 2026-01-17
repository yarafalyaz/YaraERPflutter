import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  List<String> _roles = [];
  bool _isLoading = false;

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  List<String> get roles => _roles;
  String get userName => _user?['name'] ?? 'User';
  String? get userAvatar => _user?['avatar_url'];

  // Check if user has role
  bool hasRole(String role) => _roles.contains(role);
  bool hasAnyRole(List<String> checkRoles) => 
      checkRoles.any((r) => _roles.contains(r));

  // Initialize - check stored token
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      _user = jsonDecode(userJson);
      _roles = (List<dynamic>.from(_user?['roles'] ?? []))
          .map((r) => r.toString().toLowerCase())
          .toList();
    }
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _token = data['token'];
          _user = data['user'];
          _roles = (List<dynamic>.from(_user?['roles'] ?? []))
              .map((r) => r.toString().toLowerCase())
              .toList();

          // Save to storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token!);
          await prefs.setString('user_data', jsonEncode(_user));

          notifyListeners();
          return true;
        }
      }

      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/logout'),
          headers: ApiConfig.headers(token: _token),
        );
      } catch (_) {}
    }

    _token = null;
    _user = null;
    _roles = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    notifyListeners();
  }

  // Get dashboard summary data
  Future<Map<String, dynamic>> getDashboardData() async {
    if (_token == null) return {};
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard'),
        headers: ApiConfig.headers(token: _token),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Dashboard data error: $e');
    }
    return {};
  }

  // Get dashboard metrics
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    if (_token == null) return {};
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard/metrics'),
        headers: ApiConfig.headers(token: _token),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Metrics error: $e');
    }
    return {};
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user'),
        headers: ApiConfig.headers(token: _token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data;
        _roles = (List<dynamic>.from(_user?['roles'] ?? []))
            .map((r) => r.toString().toLowerCase())
            .toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_user));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Profile refresh error: $e');
    }
  }
}
