import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/presensi_model.dart';
import '../services/api_service.dart';
import '../services/attendance_service.dart';

class PresensiViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AttendanceService _attendanceService = AttendanceService();

  // ==================== EXISTING STATE ====================

  List<PresensiModel> _presensiList = [];
  PresensiModel? _todayPresensi;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;

  static const double officeLatitude = -6.6158490522855775;
  static const double officeLongitude = 106.78558646934172;
  static const double maxDistanceInMeters = 100.0; // 100 meter radius

  // ==================== NEW STATE FOR MONTHLY ====================

  bool _isLoadingMonthly = false;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  // ==================== EXISTING GETTERS ====================

  List<PresensiModel> get presensiList => _presensiList;
  PresensiModel? get todayPresensi => _todayPresensi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;

  // ==================== NEW GETTERS ====================

  bool get isLoadingMonthly => _isLoadingMonthly;
  int get currentMonth => _currentMonth;
  int get currentYear => _currentYear;

  // ==================== EXISTING METHOD: KEEP AS IS ====================

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

  // ==================== EXISTING METHOD: KEEP AS IS ====================

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

  // ==================== NEW METHOD: MONTHLY FETCH ====================

  /// Fetch monthly attendance with optimization
  /// This is the NEW method for PresensiScreen
  Future<void> fetchMonthlyPresensi({
    int? month,
    int? year,
    bool forceRefresh = false,
  }) async {
    final targetMonth = month ?? DateTime.now().month;
    final targetYear = year ?? DateTime.now().year;

    try {
      // Optimization: Skip if already loaded
      if (!forceRefresh &&
          _currentMonth == targetMonth &&
          _currentYear == targetYear &&
          _presensiList.isNotEmpty) {
        debugPrint('📦 Using cached data for $targetMonth/$targetYear');
        return;
      }

      _isLoadingMonthly = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint(
        '📡 Fetching monthly presensi for $targetMonth/$targetYear...',
      );

      final response = await _attendanceService.getMonthlyHistory(
        month: targetMonth,
        year: targetYear,
      );

      if (response['success'] == true) {
        final List<dynamic> dataList = response['data'] as List;

        // Map API response to PresensiModel
        _presensiList = dataList.map((json) {
          return PresensiModel.fromJson({
            'id': json['id'],
            'user_id': json['user_id'],
            'date': json['date'],
            'check_in_time': json['clock_in'],
            'check_out_time': json['clock_out'],
            'check_in_lat': json['lat_in'],
            'check_in_lng': json['long_in'],
            'check_out_lat': json['lat_out'],
            'check_out_lng': json['long_out'],
            'status': json['clock_out'] != null ? 'hadir' : 'pending',
          });
        }).toList();

        // Sort by date (newest first)
        _presensiList.sort((a, b) => b.date.compareTo(a.date));

        _currentMonth = targetMonth;
        _currentYear = targetYear;

        debugPrint('✅ Loaded ${_presensiList.length} records');

        // Update today's presensi if current month
        _updateTodayPresensiFromList();
      } else {
        _errorMessage = response['error'] ?? 'Failed to fetch monthly presensi';
        debugPrint('❌ Error: $_errorMessage');
        _presensiList = [];
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      debugPrint('❌ Exception: $_errorMessage');
      _presensiList = [];
    } finally {
      _isLoadingMonthly = false;
      notifyListeners();
    }
  }

  // ==================== NEW METHOD: FILTER FROM CACHE ====================

  /// Get presensi for specific date (NO API call - filter from cache)
  PresensiModel? getPresensiForDate(DateTime date) {
    try {
      return _presensiList.firstWhere(
        (p) =>
            p.date.year == date.year &&
            p.date.month == date.month &&
            p.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if date has presensi (for calendar markers)
  bool hasPresensiForDate(DateTime date) {
    return _presensiList.any(
      (p) =>
          p.date.year == date.year &&
          p.date.month == date.month &&
          p.date.day == date.day,
    );
  }

  // ==================== NEW METHOD: REFRESH ====================

  /// Refresh current month
  Future<void> refreshCurrentMonth() async {
    await fetchMonthlyPresensi(
      month: _currentMonth,
      year: _currentYear,
      forceRefresh: true,
    );
  }

  // ==================== HELPER METHOD ====================

  /// Update today's presensi from monthly list
  void _updateTodayPresensiFromList() {
    final today = DateTime.now();

    if (today.month == _currentMonth && today.year == _currentYear) {
      _todayPresensi = getPresensiForDate(today);

      if (_todayPresensi != null) {
        debugPrint('✅ Today\'s presensi updated from monthly data');
      }
    }
  }

  // ==================== EXISTING METHOD: KEEP AS IS ====================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== NEW METHOD: CLEAR ALL ====================

  void clearAllData() {
    _presensiList = [];
    _todayPresensi = null;
    _errorMessage = null;
    _isLoading = false;
    _isLoadingMonthly = false;
    _currentPosition = null;
    _currentMonth = DateTime.now().month;
    _currentYear = DateTime.now().year;
    notifyListeners();
  }
}
