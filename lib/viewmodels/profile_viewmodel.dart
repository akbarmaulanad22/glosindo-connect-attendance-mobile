import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Set user data
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // ==================== UPDATE PROFILE ====================

  /// Update user profile and persist to SharedPreferences
  Future<bool> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? photoPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Updating profile...');

      // Call API
      final response = await _profileService.updateProfile(
        name: name,
        email: email,
        phone: phone,
        photoPath: photoPath,
      );

      if (response['success'] == true) {
        debugPrint('✅ Profile updated successfully');

        // Update local user object
        final updatedData = response['data'];
        final updatedUser = UserModel.fromJson(updatedData);

        _user = updatedUser;

        // Persist to SharedPreferences
        await _saveUserToPreferences(updatedUser);

        _isLoading = false;
        notifyListeners();

        return true;
      } else {
        debugPrint('❌ Profile update failed: ${response['error']}');
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      _errorMessage = 'Unexpected error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== SAVE TO SHARED PREFERENCES ====================

  /// Save user data to SharedPreferences
  Future<void> _saveUserToPreferences(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save as JSON string
      final userJson = json.encode(user.toJson());
      await prefs.setString('user_data', userJson);

      debugPrint('✅ User data saved to SharedPreferences');
    } catch (e) {
      debugPrint('❌ Error saving user to preferences: $e');
    }
  }

  // ==================== LOAD FROM SHARED PREFERENCES ====================

  /// Load user data from SharedPreferences
  Future<void> loadUserFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      if (userJson != null) {
        final userMap = json.decode(userJson);
        _user = UserModel.fromJson(userMap);
        notifyListeners();
        debugPrint('✅ User data loaded from SharedPreferences');
      }
    } catch (e) {
      debugPrint('❌ Error loading user from preferences: $e');
    }
  }

  // ==================== REFRESH PROFILE FROM API ====================

  /// Refresh profile data from API
  Future<void> refreshProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileService.getProfile();

      if (response['success'] == true) {
        final userData = response['data'];
        _user = UserModel.fromJson(userData);
        await _saveUserToPreferences(_user!);

        debugPrint('✅ Profile refreshed from API');
      } else {
        _errorMessage = response['error'];
        debugPrint('❌ Failed to refresh profile: ${response['error']}');
      }
    } catch (e) {
      _errorMessage = 'Failed to refresh profile';
      debugPrint('❌ Error refreshing profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== CLEAR DATA ====================

  /// Clear user data (for logout)
  Future<void> clearUser() async {
    _user = null;
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      debugPrint('✅ User data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing user data: $e');
    }

    notifyListeners();
  }
}
