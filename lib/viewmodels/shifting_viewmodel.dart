import 'package:flutter/material.dart';
import 'package:glosindo_connect/models/shifting_model.dart';
import 'package:glosindo_connect/services/api_service.dart';

class ShiftingViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ShiftingModel> _shiftList = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  List<ShiftingModel> get shiftList => _shiftList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> fetchShiftSchedule(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getShiftSchedule(startDate, endDate);
      _shiftList = (response['data'] as List)
          .map((json) => ShiftingModel.fromJson(json))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  ShiftingModel? getShiftForDate(DateTime date) {
    try {
      return _shiftList.firstWhere(
        (shift) =>
            shift.date.year == date.year &&
            shift.date.month == date.month &&
            shift.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }
}
