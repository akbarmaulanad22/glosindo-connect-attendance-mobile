import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  bool _isLoading = false;
  bool _isError = false;
  bool _isSuccess = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isError => _isError;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;

  void resetState() {
    _isLoading = false;
    _isError = false;
    _isSuccess = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    required String email,
    required Function(UserModel) onSuccess,
  }) async {
    _isLoading = true;
    _isError = false;
    _isSuccess = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileService.updateProfile(
        name: name,
        phone: phone,
        email: email,
      );

      debugPrint('📱 ViewModel - Raw Response: $response');

      if (response['success'] == true) {
        debugPrint('✅ ViewModel - Response success');

        _isLoading = false;
        _isSuccess = true;
        notifyListeners();

        // API hanya return success message tanpa data user
        // Kita perlu construct UserModel dari data yang dikirim
        // Callback akan handle update ke AuthViewModel
        onSuccess(
          UserModel(
            id: '', // Will be filled by AuthViewModel from currentUser
            nik: '', // Will be filled by AuthViewModel from currentUser
            name: name,
            email: email,
            phone: phone,
            jabatan: '', // Will be filled by AuthViewModel from currentUser
            divisi: '', // Will be filled by AuthViewModel from currentUser
            photo: null, // Will be filled by AuthViewModel from currentUser
          ),
        );

        return true;
      } else {
        debugPrint('❌ ViewModel - Response failed');
        _isLoading = false;
        _isError = true;
        _errorMessage = response['error'] ?? 'Gagal memperbarui profil';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _isError = true;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ ViewModel Error: $e');
      return false;
    }
  }

  Future<bool> updateProfilePhoto({
    required String photoPath,
    required Function(String) onSuccess,
  }) async {
    _isLoading = true;
    _isError = false;
    _isSuccess = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileService.updateProfilePhoto(
        photoPath: photoPath,
      );

      debugPrint('📱 ViewModel - Raw Response: $response');

      if (response['success'] == true) {
        debugPrint('✅ ViewModel - Photo upload success');

        final data = response['data'];

        if (data == null || data is! Map<String, dynamic>) {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Data foto tidak ditemukan dalam response';
          notifyListeners();
          return false;
        }

        final photoUrl = data['photo_url'] as String?;

        if (photoUrl == null || photoUrl.isEmpty) {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'URL foto tidak ditemukan';
          notifyListeners();
          return false;
        }

        debugPrint('✅ ViewModel - Photo URL: $photoUrl');

        _isLoading = false;
        _isSuccess = true;
        notifyListeners();

        onSuccess(photoUrl);

        return true;
      } else {
        debugPrint('❌ ViewModel - Photo upload failed');
        _isLoading = false;
        _isError = true;
        _errorMessage = response['error'] ?? 'Gagal mengunggah foto';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _isError = true;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ ViewModel Error: $e');
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _isError = false;
    _isSuccess = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      debugPrint('📱 ViewModel - Raw Response: $response');

      if (response['success'] == true) {
        debugPrint('✅ ViewModel - Password change success');
        _isLoading = false;
        _isSuccess = true;
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ ViewModel - Password change failed');
        _isLoading = false;
        _isError = true;
        _errorMessage = response['error'] ?? 'Gagal mengubah password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _isError = true;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ ViewModel Error: $e');
      return false;
    }
  }
}
