import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  UserModel? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuth() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasToken = await _apiClient.hasToken();
      if (hasToken) {
        _user = await _authService.getMe();
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      // If verification fails (e.g. token expired), sign out automatically
      await _apiClient.clearToken();
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      _user = await _authService.getMe();
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String nombre, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create the account
      await _authService.register(
        nombre: nombre,
        email: email,
        password: password,
      );
      
      // 2. Perform automatic login immediately after successful registration
      return await login(email, password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _apiClient.clearToken();
    _user = null;
    _isAuthenticated = false;
    _isLoading = false;
    
    notifyListeners();
  }
}
