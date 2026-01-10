import 'package:flutter/foundation.dart';
import 'package:glosindo_connect/models/user_model.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> _loadUserProfile() async {
    try {
      final profileResponse = await _apiService.getUserProfile();

      if (profileResponse['success'] == true) {
        _currentUser = UserModel.fromJson(profileResponse['data']);
        return true;
      } else {
        _currentUser = null;
        return false;
      }
    } catch (e) {
      debugPrint('Load profile error: $e');
      _currentUser = null;
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final success = await _loadUserProfile();

        if (success) {
          _isAuthenticated = true;
        } else {
          await prefs.clear();
          _isAuthenticated = false;
        }
        notifyListeners();
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _isAuthenticated = false;
      debugPrint('Check auth error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await _apiService.login(email, password);

      if (loginResponse['success'] != true) {
        _errorMessage =
            loginResponse['error'] ?? loginResponse['message'] ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final token = loginResponse['data']['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      final profileLoaded = await _loadUserProfile();

      if (!profileLoaded) {
        _errorMessage = 'Gagal memuat data profil';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_id', _currentUser!.id);

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
