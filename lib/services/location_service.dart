import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service untuk handle GPS location dengan validasi Mock Location (Fake GPS)
class LocationService {
  /// Check apakah location service aktif
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position dengan validasi Mock Location
  ///
  /// Returns:
  /// - Position jika valid
  /// - Throws Exception jika mock location terdeteksi atau error
  Future<Position> getCurrentPositionWithValidation() async {
    try {
      debugPrint('🔍 Getting current position...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint(
        '📍 Position obtained: ${position.latitude}, ${position.longitude}',
      );
      debugPrint('📍 Accuracy: ${position.accuracy}m');
      debugPrint('📍 Is Mock Location: ${position.isMocked}');

      // CRITICAL: Check for Mock Location (Fake GPS)
      if (position.isMocked) {
        debugPrint('❌ MOCK LOCATION DETECTED!');
        throw MockLocationException(
          'Lokasi palsu terdeteksi. Mohon matikan aplikasi Fake GPS Anda untuk melanjutkan.',
        );
      }

      // Optional: Check accuracy
      if (position.accuracy > 50) {
        debugPrint('⚠️ Low GPS accuracy: ${position.accuracy}m');
        // You can decide to throw error or just warn user
        // throw Exception('Akurasi GPS terlalu rendah. Mohon tunggu sinyal GPS yang lebih baik.');
      }

      debugPrint('✅ Position validated successfully');
      return position;
    } on MockLocationException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Error getting position: $e');
      throw Exception('Gagal mendapatkan lokasi: ${e.toString()}');
    }
  }

  /// Calculate distance between two coordinates (in meters)
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Check if user is within office radius
  ///
  /// Returns true if within radius, false otherwise
  bool isWithinOfficeRadius({
    required Position userPosition,
    required double officeLat,
    required double officeLng,
    required double radiusInMeters,
  }) {
    final distance = calculateDistance(
      startLat: userPosition.latitude,
      startLng: userPosition.longitude,
      endLat: officeLat,
      endLng: officeLng,
    );

    debugPrint('📏 Distance to office: ${distance.toStringAsFixed(2)}m');
    debugPrint('📏 Max allowed radius: ${radiusInMeters}m');

    return distance <= radiusInMeters;
  }
}

/// Custom exception untuk Mock Location detection
class MockLocationException implements Exception {
  final String message;

  MockLocationException(this.message);

  @override
  String toString() => message;
}
