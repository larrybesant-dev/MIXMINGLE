import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'image_optimization_service.dart';

class PhotoUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final ImageOptimizationService _optimizationService = ImageOptimizationService();

  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  Future<String> uploadProfilePhoto(XFile imageFile) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final String extension = imageFile.path.substring(imageFile.path.lastIndexOf('.'));
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final String path = 'profile_photos/$userId/$fileName';

      // Optimize and upload with thumbnails
      final File file = File(imageFile.path);
      final optimizedFile = await _optimizationService.optimizeImage(file);

      final urls = await _optimizationService.uploadImageWithThumbnails(
        imageFile: optimizedFile,
        path: path,
      );

      // Clean up temporary optimized file
      if (optimizedFile.path != file.path) {
        await optimizedFile.delete();
      }

      // Return the original URL (thumbnails are available at urls['thumbnail'], urls['medium'], urls['large'])
      return urls['original']!;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  Future<void> deleteProfilePhoto(String photoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(photoUrl);
      final path = ref.fullPath;

      // Delete original and all thumbnails
      await _optimizationService.deleteImageWithThumbnails(path);
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  Future<String> uploadEventPhoto(XFile imageFile, String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final String extension = imageFile.path.substring(imageFile.path.lastIndexOf('.'));
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final String path = 'event_photos/$eventId/$fileName';

      // Optimize and upload with thumbnails
      final File file = File(imageFile.path);
      final optimizedFile = await _optimizationService.optimizeImage(file);

      final urls = await _optimizationService.uploadImageWithThumbnails(
        imageFile: optimizedFile,
        path: path,
      );

      // Clean up temporary optimized file
      if (optimizedFile.path != file.path) {
        await optimizedFile.delete();
      }

      // Return the original URL (thumbnails are available at urls['thumbnail'], urls['medium'], urls['large'])
      return urls['original']!;
    } catch (e) {
      throw Exception('Failed to upload event photo: $e');
    }
  }
}
