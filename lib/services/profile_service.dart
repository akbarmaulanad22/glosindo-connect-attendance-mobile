import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class ProfileService {
  static const String baseUrl = 'https://top-gibbon-engaged.ngrok-free.app/api';

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

  // ==================== UPDATE PROFILE ====================

  /// Update user profile
  /// PUT /profile (multipart/form-data)
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? photoPath,
  }) async {
    try {
      debugPrint('📡 API Call: PUT /profile');
      debugPrint('📝 Data: name=$name, email=$email, phone=$phone');
      if (photoPath != null) {
        debugPrint('📸 Photo: $photoPath');
      }

      // Get auth token
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      // Create multipart request
      final uri = Uri.parse('$baseUrl/profile');
      final request = http.MultipartRequest('PUT', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Add text fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }

      // Add photo if provided
      if (photoPath != null && photoPath.isNotEmpty) {
        final file = File(photoPath);
        if (await file.exists()) {
          // Determine content type based on file extension
          String? mimeType;
          if (photoPath.toLowerCase().endsWith('.jpg') ||
              photoPath.toLowerCase().endsWith('.jpeg')) {
            mimeType = 'image/jpeg';
          } else if (photoPath.toLowerCase().endsWith('.png')) {
            mimeType = 'image/png';
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              'photo',
              photoPath,
              contentType: mimeType != null ? MediaType.parse(mimeType) : null,
            ),
          );
          debugPrint('✅ Photo file added to request');
        } else {
          debugPrint('⚠️ Photo file does not exist: $photoPath');
        }
      }

      // Send request
      debugPrint('📤 Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'error':
              responseData['error'] ??
              responseData['message'] ??
              'Invalid request',
        };
      } else if (response.statusCode == 422) {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'error':
              responseData['error'] ??
              responseData['message'] ??
              'Validation failed',
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'error':
              responseData['error'] ??
              responseData['message'] ??
              'Failed to update profile',
        };
      }
    } on SocketException {
      debugPrint('❌ No internet connection');
      return {
        'success': false,
        'error': 'No internet connection. Please check your network.',
      };
    } on FormatException {
      debugPrint('❌ Invalid response format');
      return {'success': false, 'error': 'Invalid response from server'};
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  // ==================== GET PROFILE ====================

  /// Get current user profile
  /// GET /profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      debugPrint('📡 API Call: GET /profile');

      // Get auth token
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      final uri = Uri.parse('$baseUrl/profile');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('✅ Response Status: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData['data']};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized - Please login again'};
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'error':
              responseData['error'] ??
              responseData['message'] ??
              'Failed to get profile',
        };
      }
    } on SocketException {
      debugPrint('❌ No internet connection');
      return {
        'success': false,
        'error': 'No internet connection. Please check your network.',
      };
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }
}
