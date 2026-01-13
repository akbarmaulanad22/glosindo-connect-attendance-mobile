import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String baseUrl = 'https://top-gibbon-engaged.ngrok-free.app/api';
  // static const String baseUrl = 'http://localhost:8080/api';

  late Dio _dio;

  ProfileService() {
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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
    required String email,
  }) async {
    try {
      debugPrint('📡 API Call: PUT /profile');
      debugPrint('📝 Data: name=$name, phone=$phone, email=$email');

      final response = await _dio.put(
        '/profile',
        data: {'name': name, 'phone': phone, 'email': email},
      );

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Raw Response Data: ${response.data}');
      debugPrint('📦 Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response.data is Map
        if (responseData is Map<String, dynamic>) {
          debugPrint('✅ Response is Map');

          // Check if 'data' key exists
          if (responseData.containsKey('data') &&
              responseData['data'] != null) {
            debugPrint('✅ Found data key');
            return {
              'success': true,
              'message':
                  responseData['message'] ?? 'Profile updated successfully',
              'data': responseData['data'],
            };
          } else {
            // If no 'data' key, return the whole response as data
            debugPrint('⚠️ No data key, using whole response');
            return {
              'success': true,
              'message':
                  responseData['message'] ?? 'Profile updated successfully',
              'data': responseData,
            };
          }
        } else if (responseData is List) {
          debugPrint('❌ Unexpected: Response is List');
          return {
            'success': false,
            'error':
                'Unexpected response format: received array instead of object',
          };
        } else {
          debugPrint('❌ Unexpected response type: ${responseData.runtimeType}');
          return {'success': false, 'error': 'Unexpected response format'};
        }
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else if (response.statusCode == 400) {
        final errorMsg = response.data is Map
            ? (response.data['error'] ??
                  response.data['message'] ??
                  'Invalid data')
            : 'Invalid data';
        return {'success': false, 'error': errorMsg};
      } else {
        final errorMsg = response.data is Map
            ? (response.data['error'] ??
                  response.data['message'] ??
                  'Update failed')
            : 'Update failed';
        return {'success': false, 'error': errorMsg};
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      debugPrint('❌ Dio Response: ${e.response?.data}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateProfilePhoto({
    required String photoPath,
  }) async {
    try {
      debugPrint('📡 API Call: POST /user/profile/photo');
      debugPrint('📸 Photo: $photoPath');

      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: photoPath.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/user/profile/photo',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: (sent, total) {
          debugPrint(
            '📤 Upload Progress: ${(sent / total * 100).toStringAsFixed(0)}%',
          );
        },
      );

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Raw Response Data: ${response.data}');
      debugPrint('📦 Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          debugPrint('✅ Response is Map');

          // Try to extract photo_url from different possible locations
          String? photoUrl;

          if (responseData.containsKey('data') &&
              responseData['data'] != null) {
            final data = responseData['data'];
            if (data is Map<String, dynamic>) {
              photoUrl = data['photo_url'] ?? data['photo'];
            } else if (data is String) {
              photoUrl = data;
            }
          } else if (responseData.containsKey('photo_url')) {
            photoUrl = responseData['photo_url'];
          } else if (responseData.containsKey('photo')) {
            photoUrl = responseData['photo'];
          }

          if (photoUrl != null) {
            return {
              'success': true,
              'message':
                  responseData['message'] ?? 'Photo updated successfully',
              'data': {'photo_url': photoUrl},
            };
          } else {
            debugPrint('⚠️ Photo URL not found in response');
            return {
              'success': false,
              'error': 'Photo URL not found in response',
            };
          }
        } else {
          debugPrint('❌ Unexpected response type: ${responseData.runtimeType}');
          return {'success': false, 'error': 'Unexpected response format'};
        }
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else if (response.statusCode == 400) {
        final errorMsg = response.data is Map
            ? (response.data['error'] ??
                  response.data['message'] ??
                  'Invalid photo')
            : 'Invalid photo';
        return {'success': false, 'error': errorMsg};
      } else {
        final errorMsg = response.data is Map
            ? (response.data['error'] ??
                  response.data['message'] ??
                  'Upload failed')
            : 'Upload failed';
        return {'success': false, 'error': errorMsg};
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      debugPrint('❌ Dio Response: ${e.response?.data}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint('📡 API Call: PUT /user/change-password');

      final response = await _dio.put(
        '/user/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Raw Response Data: ${response.data}');
      debugPrint('📦 Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        final message = responseData is Map<String, dynamic>
            ? (responseData['message'] ?? 'Password changed successfully')
            : 'Password changed successfully';

        return {'success': true, 'message': message};
      } else if (response.statusCode == 401) {
        final errorMsg = response.data is Map<String, dynamic>
            ? (response.data['error'] ?? 'Unauthorized - Please login again')
            : 'Unauthorized - Please login again';
        return {'success': false, 'error': errorMsg};
      } else if (response.statusCode == 400) {
        final errorMsg = response.data is Map<String, dynamic>
            ? (response.data['error'] ??
                  response.data['message'] ??
                  'Invalid password')
            : 'Invalid password';
        return {'success': false, 'error': errorMsg};
      } else {
        final errorMsg = response.data is Map<String, dynamic>
            ? (response.data['error'] ??
                  response.data['message'] ??
                  'Password change failed')
            : 'Password change failed';
        return {'success': false, 'error': errorMsg};
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      debugPrint('❌ Dio Response: ${e.response?.data}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

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
