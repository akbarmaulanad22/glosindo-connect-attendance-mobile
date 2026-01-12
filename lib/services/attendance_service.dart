import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  static const String baseUrl = 'https://top-gibbon-engaged.ngrok-free.app/api';
  // static const String baseUrl = 'http://localhost:8080/api';

  late Dio _dio;

  AttendanceService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) {
          // Accept all status codes to handle them manually
          return status! < 500;
        },
      ),
    );

    // Add interceptor for logging (debug only)
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: true,
        ),
      );
    }

    // Add interceptor for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token from SharedPreferences
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('❌ Dio Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  // Get auth token from SharedPreferences
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // ==================== GET TODAY'S ATTENDANCE ====================

  /// Check today's attendance status
  /// GET /attendance/today
  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      debugPrint('📡 API Call: GET /attendance/today');

      final response = await _dio.get('/attendance/today');

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        // Parse response
        final responseData = response.data;

        // Check if data exists (user has attendance today)
        if (responseData['data'] != null) {
          debugPrint('✅ Attendance data found');
          return {
            'success': true,
            'hasAttendance': true,
            'data': responseData['data'],
          };
        } else {
          // No attendance today - this is OK
          debugPrint('ℹ️ No attendance data for today');
          return {'success': true, 'hasAttendance': false, 'data': null};
        }
      } else if (response.statusCode == 404) {
        // Not found - no attendance today (this is OK, not an error)
        debugPrint('ℹ️ 404 - No attendance today');
        return {'success': true, 'hasAttendance': false, 'data': null};
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized');
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else {
        debugPrint('❌ Unexpected status code: ${response.statusCode}');
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to get today attendance',
        };
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  // ==================== GET MONTHLY ATTENDANCE HISTORY ====================

  /// Fetch monthly attendance history
  /// GET /attendance/monthly?month={month}&year={year}
  Future<Map<String, dynamic>> getMonthlyHistory({
    required int month,
    required int year,
  }) async {
    try {
      debugPrint('📡 API Call: GET /attendance/monthly');
      debugPrint('📅 Parameters: month=$month, year=$year');

      // Validate parameters
      if (month < 1 || month > 12) {
        return {
          'success': false,
          'error': 'Invalid month: must be between 1 and 12',
        };
      }

      if (year < 2000 || year > 2100) {
        return {
          'success': false,
          'error': 'Invalid year: must be between 2000 and 2100',
        };
      }

      // Build query parameters
      final queryParams = {'month': month.toString(), 'year': year.toString()};

      final response = await _dio.get(
        '/attendance/monthly',
        queryParameters: queryParams,
      );

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if data exists
        if (responseData['data'] != null) {
          final List<dynamic> dataList = responseData['data'] as List;

          debugPrint('✅ Found ${dataList.length} attendance records');

          return {'success': true, 'data': dataList, 'count': dataList.length};
        } else {
          // No data for this month
          debugPrint('ℹ️ No attendance data for this month');
          return {'success': true, 'data': [], 'count': 0};
        }
      } else if (response.statusCode == 404) {
        // No data found - this is OK
        debugPrint('ℹ️ 404 - No attendance data for this month');
        return {'success': true, 'data': [], 'count': 0};
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized');
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else if (response.statusCode == 400) {
        // Bad request - invalid parameters
        final error =
            response.data['error'] ??
            response.data['message'] ??
            'Invalid request parameters';
        debugPrint('❌ Bad Request: $error');
        return {'success': false, 'error': error};
      } else {
        debugPrint('❌ Unexpected status code: ${response.statusCode}');
        return {
          'success': false,
          'error':
              response.data['error'] ??
              response.data['message'] ??
              'Failed to get monthly attendance',
        };
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  // ==================== GET ATTENDANCE HISTORY ====================

  /// Fetch attendance logs
  /// GET /attendance/history
  Future<Map<String, dynamic>> getAttendanceHistory({
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    try {
      debugPrint('📡 API Call: GET /attendance/history');

      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _dio.get(
        '/attendance/history',
        queryParameters: queryParams,
      );

      debugPrint('✅ Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data['data']};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else {
        return {
          'success': false,
          'error':
              response.data['message'] ?? 'Failed to get attendance history',
        };
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  // ==================== CLOCK IN ====================

  /// Submit check-in attendance
  /// POST /attendance/clock-in (multipart/form-data)
  Future<Map<String, dynamic>> clockIn({
    required String photoPath,
    required String latitude,
    required String longitude,
  }) async {
    try {
      debugPrint('📡 API Call: POST /attendance/clock-in');
      debugPrint('📸 Photo: $photoPath');
      debugPrint('📍 Location: $latitude, $longitude');

      // Create FormData for multipart request
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: photoPath.split('/').last,
        ),
        'latitude': latitude,
        'longitude': longitude,
      });

      final response = await _dio.post(
        '/attendance/clock-in',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: (sent, total) {
          debugPrint(
            '📤 Upload Progress: ${(sent / total * 100).toStringAsFixed(0)}%',
          );
        },
      );

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Clock-in successful',
          'data': response.data['data'],
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'error':
              response.data['error'] ??
              response.data['message'] ??
              'Invalid request',
        };
      } else {
        return {
          'success': false,
          'error':
              response.data['error'] ??
              response.data['message'] ??
              'Clock-in failed',
        };
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  // ==================== CLOCK OUT ====================

  /// Submit check-out attendance
  /// POST /attendance/clock-out (multipart/form-data)
  Future<Map<String, dynamic>> clockOut({
    required String photoPath,
    required String latitude,
    required String longitude,
  }) async {
    try {
      debugPrint('📡 API Call: POST /attendance/clock-out');
      debugPrint('📸 Photo: $photoPath');
      debugPrint('📍 Location: $latitude, $longitude');

      // Create FormData for multipart request
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: photoPath.split('/').last,
        ),
        'latitude': latitude,
        'longitude': longitude,
      });

      final response = await _dio.post(
        '/attendance/clock-out',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: (sent, total) {
          debugPrint(
            '📤 Upload Progress: ${(sent / total * 100).toStringAsFixed(0)}%',
          );
        },
      );

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Clock-out successful',
          'data': response.data['data'],
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'error':
              response.data['error'] ??
              response.data['message'] ??
              'Invalid request',
        };
      } else {
        return {
          'success': false,
          'error':
              response.data['error'] ??
              response.data['message'] ??
              'Clock-out failed',
        };
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  // ==================== ERROR HANDLER ====================

  Map<String, dynamic> _handleDioError(DioException e) {
    String errorMessage;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage =
            'Connection timeout. Please check your internet connection.';
        break;

      case DioExceptionType.badResponse:
        errorMessage = 'Server error: ${e.response?.statusCode}';
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;

      case DioExceptionType.connectionError:
        errorMessage = 'No internet connection. Please check your network.';
        break;

      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          errorMessage = 'No internet connection';
        } else {
          errorMessage = 'Unexpected error occurred';
        }
        break;

      default:
        errorMessage = 'Unknown error: ${e.message}';
    }

    return {'success': false, 'error': errorMessage};
  }
}
