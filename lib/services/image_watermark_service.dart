import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Service untuk image processing dan watermarking
class ImageWatermarkService {
  /// Add watermark to image with GPS coordinates and timestamp
  ///
  /// Parameters:
  /// - [imagePath]: Path to original image
  /// - [latitude]: GPS latitude
  /// - [longitude]: GPS longitude
  ///
  /// Returns: Path to watermarked image
  Future<String> addWatermark({
    required String imagePath,
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint('🎨 Starting watermark process...');
      debugPrint('📸 Original image: $imagePath');

      // Read original image
      final File imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();

      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      debugPrint('📐 Image size: ${image.width}x${image.height}');

      // Prepare watermark text
      final DateTime now = DateTime.now();
      final String dateTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
      final String coordinates =
          'Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}';

      debugPrint('📝 Watermark text:');
      debugPrint('   DateTime: $dateTime');
      debugPrint('   Coordinates: $coordinates');

      // Calculate dimensions
      final int rectHeight = (image.height * 0.15).round().clamp(80, 150);
      final int rectY = image.height - rectHeight;
      final int padding = 20;
      final int lineHeight = 35;

      // Draw semi-transparent black rectangle at bottom
      img.fillRect(
        image,
        x1: 0,
        y1: rectY,
        x2: image.width,
        y2: image.height,
        color: img.ColorRgba8(0, 0, 0, 200), // Semi-transparent black
      );

      // Draw datetime text (using built-in bitmap font)
      img.drawString(
        image,
        dateTime,
        font: img.arial48,
        x: padding,
        y: rectY + padding,
        color: img.ColorRgba8(255, 255, 255, 255), // White
      );

      // Draw coordinates text
      img.drawString(
        image,
        coordinates,
        font: img.arial48,
        x: padding,
        y: rectY + padding + lineHeight,
        color: img.ColorRgba8(255, 255, 255, 255), // White
      );

      debugPrint('✅ Watermark applied');

      // Save watermarked image
      final Directory tempDir = await getTemporaryDirectory();
      final String watermarkedPath =
          '${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final File watermarkedFile = File(watermarkedPath);
      await watermarkedFile.writeAsBytes(img.encodeJpg(image, quality: 90));

      debugPrint('💾 Watermarked image saved: $watermarkedPath');
      debugPrint('📦 File size: ${await watermarkedFile.length()} bytes');

      return watermarkedPath;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding watermark: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Gagal menambahkan watermark: ${e.toString()}');
    }
  }

  /// Compress image if needed (optional, can be used before watermarking)
  Future<File> compressImage(String imagePath, {int quality = 85}) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large (max 1920px width)
      if (image.width > 1920) {
        final int newHeight = (image.height * 1920 / image.width).round();
        image = img.copyResize(image, width: 1920, height: newHeight);
      }

      // Save compressed image
      final Directory tempDir = await getTemporaryDirectory();
      final String compressedPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final File compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(img.encodeJpg(image, quality: quality));

      debugPrint('📦 Image compressed: $compressedPath');

      return compressedFile;
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      throw Exception('Gagal mengompres gambar: ${e.toString()}');
    }
  }

  /// Delete temporary watermarked images (cleanup)
  Future<void> cleanupTempImages() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();

      for (var file in files) {
        if (file.path.contains('watermarked_') ||
            file.path.contains('compressed_')) {
          await file.delete();
          debugPrint('🗑️ Deleted temp file: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error cleaning temp images: $e');
    }
  }
}
