import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthController with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  // Register
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.post(
        '/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _setLoading(false);
        return true;
      }
      _errorMessage = 'Registration failed: ${response.statusMessage}';
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      // Postman script: if (jsonData.success && jsonData.token)
      final data = response.data;
      if (data is Map && data['success'] == true && data['token'] != null) {
        final token = data['token'];

        // Save Token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);

        // Fetch user profile immediately
        await getUserProfile();

        _setLoading(false);
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Login failed';
        _setLoading(false);
        return false;
      }
    } on DioException catch (e) {
      _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  // Get User Profile
  Future<void> getUserProfile() async {
    try {
      final response = await _apiService.dio.get('/user');
      if (response.statusCode == 200) {
        print('User Data Response: ${response.data}'); // Debugging
        dynamic data = response.data;
        if (data is Map && data.containsKey('data')) {
          data = data['data'];
        }
        if (data is Map<String, dynamic>) {
          _user = User.fromJson(data);
        } else if (data is Map) {
          _user = User.fromJson(Map<String, dynamic>.from(data));
        }
        notifyListeners();
      }
    } on DioException catch (e) {
      print('Error fetching profile: ${e.message}');
      // If 401, maybe logout?
      if (e.response?.statusCode == 401) {
        await logout();
      }
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.dio.post('/logout');
    } catch (e) {
      print("Logout API error: $e");
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      _user = null;
      notifyListeners();
    }
  }

  // Auto Login Check
  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token != null) {
      await getUserProfile();
      return _user != null;
    }
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleError(DioException e) {
    if (e.response != null) {
      _errorMessage = e.response?.data['message'] ?? e.message;
    } else {
      _errorMessage = e.message ?? 'An unknown error occurred';
    }
    print("Error: $_errorMessage");
  }
}
