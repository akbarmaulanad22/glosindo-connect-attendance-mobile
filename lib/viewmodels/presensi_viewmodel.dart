import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/presensi_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class PresensiViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  List<PresensiModel> _presensiList = [];
  PresensiModel? _todayPresensi;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;

  // Koordinat kantor (contoh: Jakarta)
  static const double officeLatitude = -6.200000;
  static const double officeLongitude = 106.816666;
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

  Future<bool> checkIn() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Cek permission lokasi
      final hasPermission = await _locationService.checkLocationPermission();
      if (!hasPermission) {
        _errorMessage = 'Izin lokasi diperlukan untuk presensi';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Dapatkan posisi saat ini
      _currentPosition = await _locationService.getCurrentLocation();

      // 3. Validasi jarak ke kantor (geofencing)
      final distance = Geolocator.distanceBetween(
        officeLatitude,
        officeLongitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (distance > maxDistanceInMeters) {
        _errorMessage =
            'Anda terlalu jauh dari kantor (${distance.toStringAsFixed(0)}m). Maksimal $maxDistanceInMeters meter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 4. Kirim data ke API
      final response = await _apiService.checkIn(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      if (response['success']) {
        _todayPresensi = PresensiModel.fromJson(response['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Check-in gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sama seperti checkIn
      final hasPermission = await _locationService.checkLocationPermission();
      if (!hasPermission) {
        _errorMessage = 'Izin lokasi diperlukan untuk presensi';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentPosition = await _locationService.getCurrentLocation();

      final distance = Geolocator.distanceBetween(
        officeLatitude,
        officeLongitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (distance > maxDistanceInMeters) {
        _errorMessage =
            'Anda terlalu jauh dari kantor (${distance.toStringAsFixed(0)}m)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _apiService.checkOut(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      if (response['success']) {
        _todayPresensi = PresensiModel.fromJson(response['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Check-out gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
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
