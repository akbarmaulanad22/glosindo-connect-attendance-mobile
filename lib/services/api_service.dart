import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://top-gibbon-engaged.ngrok-free.app/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': "true",
    };
  }

  // ==================== AUTH ENDPOINTS ====================

  // Login endpoint
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': "true",
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        return responseBody;
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'error':
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Get profile error: $e');
      return {
        'success': false,
        'error': 'Tidak dapat memuat profil. Periksa koneksi internet Anda.',
      };
    }
  }

  // ==================== PRESENSI ENDPOINTS ====================

  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/presensi/check-in'),
        headers: headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Check-in failed');
      }
    } catch (e) {
      // Mock response
      return {
        'success': true,
        'message': 'Check-in berhasil',
        'data': {
          'id': '1',
          'user_id': '1',
          'date': DateTime.now().toIso8601String(),
          'check_in_time': DateTime.now().toIso8601String(),
          'check_in_lat': latitude,
          'check_in_lng': longitude,
          'status': 'hadir',
        },
      };
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/presensi/check-out'),
        headers: headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Check-out failed');
      }
    } catch (e) {
      // Mock response
      return {
        'success': true,
        'message': 'Check-out berhasil',
        'data': {
          'id': '1',
          'user_id': '1',
          'date': DateTime.now().toIso8601String(),
          'check_in_time': DateTime.now()
              .subtract(const Duration(hours: 8))
              .toIso8601String(),
          'check_out_time': DateTime.now().toIso8601String(),
          'check_out_lat': latitude,
          'check_out_lng': longitude,
          'status': 'hadir',
        },
      };
    }
  }

  Future<Map<String, dynamic>> getTodayPresensi() async {
    // Mock response
    return {'success': true, 'data': null};
  }

  Future<Map<String, dynamic>> getPresensiHistory() async {
    // Mock response
    return {'success': true, 'data': []};
  }

  // ==================== TIKET ENDPOINTS ====================

  Future<Map<String, dynamic>> getTikets({
    String? search,
    String? category,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/tikets';
      if (search != null || category != null) {
        url += '?';
        if (search != null) url += 'search=$search&';
        if (category != null) url += 'category=$category';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load tikets');
      }
    } catch (e) {
      // Mock response
      return {'success': true, 'data': _getMockTikets()};
    }
  }

  Future<Map<String, dynamic>> updateTiketStatus(
    String id,
    String status,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/tikets/$id'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update tiket');
      }
    } catch (e) {
      return {'success': true, 'message': 'Status tiket berhasil diupdate'};
    }
  }

  // ==================== KASBON ENDPOINTS ====================

  Future<Map<String, dynamic>> submitKasbon(
    double amount,
    String reason,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/kasbon'),
        headers: headers,
        body: jsonEncode({'amount': amount, 'reason': reason}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit kasbon');
      }
    } catch (e) {
      return {'success': true, 'message': 'Pengajuan kasbon berhasil dikirim'};
    }
  }

  Future<Map<String, dynamic>> getKasbonList() async {
    return {'success': true, 'data': []};
  }

  // ==================== PENGAJUAN ENDPOINTS ====================

  Future<Map<String, dynamic>> submitPengajuan(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/pengajuan'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit pengajuan');
      }
    } catch (e) {
      return {'success': true, 'message': 'Pengajuan berhasil dikirim'};
    }
  }

  Future<Map<String, dynamic>> getPengajuanList(String type) async {
    return {'success': true, 'data': []};
  }

  // ==================== SHIFTING ENDPOINTS ====================

  Future<Map<String, dynamic>> getShiftSchedule(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return {'success': true, 'data': _getMockShifts()};
  }

  // ==================== MOCK DATA HELPERS ====================

  List<Map<String, dynamic>> _getMockTikets() {
    return [
      {
        'id': '1',
        'title': 'Server Down',
        'description': 'Server production mengalami downtime',
        'category': 'Technical',
        'status': 'Open',
        'priority': 'High',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      },
      {
        'id': '2',
        'title': 'Maintenance AC',
        'description': 'AC ruangan meeting tidak dingin',
        'category': 'Maintenance',
        'status': 'On Progress',
        'priority': 'Medium',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
    ];
  }

  List<Map<String, dynamic>> _getMockShifts() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.add(Duration(days: index));
      return {
        'id': '${index + 1}',
        'user_id': '1',
        'date': date.toIso8601String(),
        'shift_type': index % 3 == 0
            ? 'pagi'
            : (index % 3 == 1 ? 'siang' : 'malam'),
        'start_time': index % 3 == 0
            ? '08:00'
            : (index % 3 == 1 ? '14:00' : '20:00'),
        'end_time': index % 3 == 0
            ? '16:00'
            : (index % 3 == 1 ? '22:00' : '04:00'),
        'location': 'Kantor Pusat',
      };
    });
  }
}
