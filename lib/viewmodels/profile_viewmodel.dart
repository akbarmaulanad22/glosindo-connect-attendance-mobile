import 'package:flutter/material.dart';
import 'package:glosindo_connect/models/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      if (_user != null) {
        _user = UserModel(
          id: _user!.id,
          nik: _user!.nik,
          name: name ?? _user!.name,
          email: email ?? _user!.email,
          phone: phone ?? _user!.phone,
          photo: _user!.photo,
          jabatan: _user!.jabatan,
          divisi: _user!.divisi,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
