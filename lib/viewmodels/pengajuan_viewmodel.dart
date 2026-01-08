import 'package:flutter/material.dart';
import 'package:glosindo_connect/models/pengajuan_model.dart';
import 'package:glosindo_connect/services/api_service.dart';

class PengajuanViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PengajuanModel> _pengajuanList = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedType = 'lembur';

  List<PengajuanModel> get pengajuanList =>
      _pengajuanList.where((p) => p.type == _selectedType).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedType => _selectedType;

  void setSelectedType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  Future<void> fetchPengajuanList(String type) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getPengajuanList(type);
      _pengajuanList = (response['data'] as List)
          .map((json) => PengajuanModel.fromJson(json))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitPengajuan({
    required String type,
    required DateTime startDate,
    DateTime? endDate,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'type': type,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'reason': reason,
      };

      final response = await _apiService.submitPengajuan(data);
      if (response['success']) {
        await fetchPengajuanList(type);
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
