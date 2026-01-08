import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ==================== API SERVICE ====================
class ApiService {
  // Ganti dengan URL API Anda
  static const String baseUrl = 'https://api.glosindo.com/api/v1';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // final response = await http.post(
      //   Uri.parse('$baseUrl/auth/login'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'email': email, 'password': password}),
      // );

      // if (response.statusCode == 200) {
      //   return jsonDecode(response.body);
      // } else {
      //   throw Exception('Login failed: ${response.statusCode}');
      // }
      if (email == "Admin@gmail.com" && password == "palelu") {
        return {
          'success': true,
          'message': 'Login berhasil',
          'data': {
            'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
            'user': {
              'id': '1',
              'nik': '123456',
              'name': 'John Doe',
              'email': email,
              'jabatan': 'Software Engineer',
              'divisi': 'IT Department',
            },
          },
        };
      } else {
        // throw Exception('Login failed: ${response.statusCode}');
        throw Exception('Login failed: 401');
      }
    } catch (e) {
      // Mock response untuk testing
      return {
        'success': true,
        'message': 'Login berhasil',
        'data': {
          'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': '1',
            'nik': '123456',
            'name': 'John Doe',
            'email': email,
            'jabatan': 'Software Engineer',
            'divisi': 'IT Department',
          },
        },
      };
    }
  }

  // Presensi endpoints
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
    return {
      'success': true,
      'data': null, // null jika belum presensi hari ini
    };
  }

  Future<Map<String, dynamic>> getPresensiHistory() async {
    // Mock response
    return {'success': true, 'data': []};
  }

  // Tiket endpoints
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

  // Kasbon endpoints
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

  // Pengajuan (Lembur, Izin, Cuti) endpoints
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

  // Shifting endpoints
  Future<Map<String, dynamic>> getShiftSchedule(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return {'success': true, 'data': _getMockShifts()};
  }

  // Mock data helpers
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
