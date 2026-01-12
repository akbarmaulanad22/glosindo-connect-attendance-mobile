import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:glosindo_connect/models/progress_ticket.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressTicketService {
  static const String baseUrl = 'https://top-gibbon-engaged.ngrok-free.app/api';

  late Dio _dio;

  ProgressTicketService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) {
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

    // Add interceptor for auth token and ngrok header
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token from SharedPreferences
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // CRITICAL: Add ngrok-skip-browser-warning header
          options.headers['ngrok-skip-browser-warning'] = 'true';

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

  // ==================== GET ALL PROGRESS TICKETS ====================

  /// Fetch all progress tickets
  /// GET /progress-ticket
  Future<Map<String, dynamic>> getAllTickets() async {
    try {
      debugPrint('📡 API Call: GET /progress-ticket');

      final response = await _dio.get('/progress-ticket');

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['data'] != null) {
          final List<dynamic> dataList = responseData['data'] as List;

          debugPrint('✅ Found ${dataList.length} tickets');

          return {'success': true, 'data': dataList, 'count': dataList.length};
        } else {
          debugPrint('ℹ️ No tickets found');
          return {'success': true, 'data': [], 'count': 0};
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized');
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else if (response.statusCode == 404) {
        debugPrint('ℹ️ 404 - No tickets found');
        return {'success': true, 'data': [], 'count': 0};
      } else {
        debugPrint('❌ Unexpected status code: ${response.statusCode}');
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch tickets',
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

  // ==================== UPDATE TICKET STATUS ====================

  /// Update ticket status
  /// PUT /progress-ticket/{id}
  ///
  /// CRITICAL Headers:
  /// - Authorization: Bearer {token}
  /// - ngrok-skip-browser-warning: true
  /// - Content-Type: application/json
  ///
  /// Request Body:
  /// ```json
  /// {
  ///   "status": "On Progress"
  /// }
  /// ```
  ///
  /// Response: Empty body (200 OK on success)
  Future<Map<String, dynamic>> updateTicketStatus({
    required String ticketId,
    required String newStatus,
  }) async {
    try {
      debugPrint('📡 API Call: PUT /progress-ticket/$ticketId');
      debugPrint('📝 New Status: $newStatus');

      // Validate status
      if (!TicketStatus.all.contains(newStatus)) {
        return {'success': false, 'error': 'Invalid status: $newStatus'};
      }

      // Prepare request body
      final requestBody = {'status': newStatus};

      final response = await _dio.put(
        '/progress-ticket/$ticketId',
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Response Data: ${response.data}');

      // Success: 200-299 status codes
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint('✅ Status updated successfully');
        return {'success': true, 'message': 'Status updated to $newStatus'};
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized');
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else if (response.statusCode == 404) {
        debugPrint('❌ Ticket not found');
        return {'success': false, 'error': 'Ticket not found'};
      } else if (response.statusCode == 400) {
        debugPrint('❌ Bad request');
        return {
          'success': false,
          'error':
              response.data['error'] ??
              response.data['message'] ??
              'Invalid request',
        };
      } else {
        debugPrint('❌ Unexpected status code: ${response.statusCode}');
        return {'success': false, 'error': 'Failed to update status'};
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
        errorMessage = 'Connection timeout. Please check your internet.';
        break;

      case DioExceptionType.badResponse:
        errorMessage = 'Server error: ${e.response?.statusCode}';
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;

      case DioExceptionType.connectionError:
        errorMessage = 'No internet connection.';
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
