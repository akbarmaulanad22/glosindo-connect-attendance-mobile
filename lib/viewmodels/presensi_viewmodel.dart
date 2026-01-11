import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/presensi_model.dart';
import '../services/api_service.dart';

class PresensiViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PresensiModel> _presensiList = [];
  PresensiModel? _todayPresensi;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;

  static const double officeLatitude = -6.6158490522855775;
  static const double officeLongitude = 106.78558646934172;
  static const double maxDistanceInMeters = 100.0; // 100 meter radius

  List<PresensiModel> get presensiList => _presensiList;
  PresensiModel? get todayPresensi => _todayPresensi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;

  Future<void> fetchPresensiHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getPresensiHistory();
      _presensiList = (response['data'] as List)
          .map((json) => PresensiModel.fromJson(json))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodayPresensi() async {
    try {
      final response = await _apiService.getTodayPresensi();
      if (response['data'] != null) {
        _todayPresensi = PresensiModel.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching today presensi: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
