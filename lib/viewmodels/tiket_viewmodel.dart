import 'package:flutter/material.dart';
import 'package:glosindo_connect/models/tiket_model.dart';
import 'package:glosindo_connect/services/api_service.dart';

class TiketViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<TiketModel> _tiketList = [];
  List<TiketModel> _filteredTiketList = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  List<TiketModel> get tiketList => _filteredTiketList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  Map<String, int> get statusCount {
    return {
      'Open': _tiketList.where((t) => t.status == 'Open').length,
      'On Progress': _tiketList.where((t) => t.status == 'On Progress').length,
      'Closed': _tiketList.where((t) => t.status == 'Closed').length,
    };
  }

  Future<void> fetchTikets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getTikets();
      _tiketList = (response['data'] as List)
          .map((json) => TiketModel.fromJson(json))
          .toList();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchTikets(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredTiketList = _tiketList.where((tiket) {
      final matchesSearch =
          tiket.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tiket.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Semua' || tiket.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
    notifyListeners();
  }

  Future<bool> updateStatus(String tiketId, String newStatus) async {
    try {
      await _apiService.updateTiketStatus(tiketId, newStatus);
      await fetchTikets();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
