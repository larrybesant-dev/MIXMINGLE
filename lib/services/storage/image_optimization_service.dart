import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import '../../core/utils/performance_logger.dart';
import '../../core/utils/app_logger.dart';

class ImageOptimizationService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image with automatic thumbnail generation
  /// Returns a map with 'original', 'large', 'medium', and 'thumbnail' URLs
  Future<Map<String, String>> uploadImageWithThumbnails({
    required File imageFile,
    required String path,
    List<ThumbnailSize> sizes = const [
      ThumbnailSize.thumbnail,
      ThumbnailSize.medium,
      ThumbnailSize.large,
    ],
  }) async {
    return await PerformanceLogger.measureAsync('uploadImageWithThumbnails', () async {
      final urls = <String, String>{};

      // Upload original
      final originalUrl = await _uploadFile(imageFile, path);
      urls['original'] = originalUrl;

      // Generate and upload thumbnails
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage != null) {
        for (final size in sizes) {
          final thumbnail = await _generateThumbnail(originalImage, size);
          if (thumbnail != null) {
            final thumbnailPath = _getThumbnailPath(path, size);
            final thumbnailUrl = await _uploadBytes(thumbnail, thumbnailPath);
            urls[size.name] = thumbnailUrl;
          }
        }
      }

      return urls;
    });
  }

  /// Generates a thumbnail from an image
  Future<Uint8List?> _generateThumbnail(img.Image image, ThumbnailSize size) async {
    return await compute(_generateThumbnailIsolate, {
      'image': image,
      'size': size,
    });
  }

  /// Isolate function for generating thumbnails (offloads from main thread)
  static Uint8List? _generateThumbnailIsolate(Map<String, dynamic> params) {
    final image = params['image'] as img.Image;
    final size = params['size'] as ThumbnailSize;

    // Resize image maintaining aspect ratio
    final resized = img.copyResize(
      image,
      width: size.width,
      height: size.height,
      interpolation: img.Interpolation.linear,
    );

    // Encode to JPEG with quality optimization
    return Uint8List.fromList(img.encodeJpg(resized, quality: size.quality));
  }

  /// Uploads a file to Firebase Storage
  Future<String> _uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Uploads bytes to Firebase Storage
  Future<String> _uploadBytes(Uint8List bytes, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  /// Gets the path for a thumbnail based on the original path
  String _getThumbnailPath(String originalPath, ThumbnailSize size) {
    final lastSlash = originalPath.lastIndexOf('/');
    final directory = originalPath.substring(0, lastSlash);
    final filename = originalPath.substring(lastSlash + 1);
    final lastDot = filename.lastIndexOf('.');
    final name = filename.substring(0, lastDot);
    final extension = filename.substring(lastDot);
    return '$directory/${name}_${size.name}$extension';
  }

  /// Deletes an image and all its thumbnails
  Future<void> deleteImageWithThumbnails(String path) async {
    try {
      // Delete original
      await _storage.ref().child(path).delete();

      // Delete thumbnails
      for (final size in ThumbnailSize.values) {
        try {
          final thumbnailPath = _getThumbnailPath(path, size);
          await _storage.ref().child(thumbnailPath).delete();
        } catch (e) {
          // Ignore if thumbnail doesn't exist
          if (kDebugMode) {
            AppLogger.warning('Could not delete thumbnail', 'Path: $path, Size: ${size.name}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error deleting image', e);
      }
      rethrow;
    }
  }

  /// Optimizes an existing image file before upload
  /// Reduces file size while maintaining acceptable quality
  Future<File> optimizeImage(File imageFile, {int maxWidth = 1920, int quality = 85}) async {
    return await PerformanceLogger.measureAsync('optimizeImage', () async {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) return imageFile;

      // Resize if needed
      final resized = image.width > maxWidth
          ? img.copyResize(image, width: maxWidth, interpolation: img.Interpolation.linear)
          : image;

      // Encode with quality compression
      final optimized = img.encodeJpg(resized, quality: quality);

      // Write to temporary file
      final tempDir = imageFile.parent;
      final tempPath = '${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final optimizedFile = File(tempPath);
      await optimizedFile.writeAsBytes(optimized);

      if (kDebugMode) {
        final originalSize = imageBytes.length / 1024; // KB
        final optimizedSize = optimized.length / 1024; // KB
        final reduction = ((originalSize - optimizedSize) / originalSize * 100).toStringAsFixed(1);
        AppLogger.info(
            'Image optimized: ${originalSize.toStringAsFixed(1)}KB â†’ ${optimizedSize.toStringAsFixed(1)}KB ($reduction% reduction)');
      }

      return optimizedFile;
    });
  }
}

/// Predefined thumbnail sizes for different use cases
enum ThumbnailSize {
  thumbnail(150, 150, 80), // Small avatars, grid previews
  medium(400, 400, 85), // List items, cards
  large(800, 800, 90); // Detail views, lightbox preview

  const ThumbnailSize(this.width, this.height, this.quality);

  final int width;
  final int height;
  final int quality;
}


