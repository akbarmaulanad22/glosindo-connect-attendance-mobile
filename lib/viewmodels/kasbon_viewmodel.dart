import 'package:flutter/material.dart';
import 'package:glosindo_connect/models/kasbon_model.dart';
import 'package:glosindo_connect/services/api_service.dart';

class KasbonViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<KasbonModel> _kasbonList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<KasbonModel> get kasbonList => _kasbonList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchKasbonList() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getKasbonList();
      _kasbonList = (response['data'] as List)
          .map((json) => KasbonModel.fromJson(json))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitKasbon(double amount, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.submitKasbon(amount, reason);
      if (response['success']) {
        await fetchKasbonList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Pengajuan gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
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
