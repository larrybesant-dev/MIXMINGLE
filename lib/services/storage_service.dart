import 'dart:io' show File;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(XFile image, String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      if (kIsWeb) {
        // For web, use bytes instead of file path
        final bytes = await image.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // For mobile, use file path
        await ref.putFile(File(image.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String?> uploadVideo(XFile video, String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/videos/${DateTime.now().millisecondsSinceEpoch}.mp4');

      if (kIsWeb) {
        // For web, use bytes instead of file path
        final bytes = await video.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'video/mp4'));
      } else {
        // For mobile, use file path
        await ref.putFile(File(video.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  Future<String?> uploadFile(File file, String userId, String fileName) async {
    try {
      final ref = _storage.ref().child('users/$userId/files/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Convenience aliases for common naming patterns
  Future<String?> uploadImageFromXFile(XFile image, String userId) => uploadImage(image, userId);

  Future<String?> uploadProfileImageFromXFile(XFile image, String userId) => uploadImage(image, userId);

  // Upload avatar with specific path
  Future<String?> uploadAvatar(XFile image, String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/avatar.jpg');

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(image.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  // Upload cover photo
  Future<String?> uploadCoverPhoto(XFile image, String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/cover.jpg');

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(image.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload cover photo: $e');
    }
  }

  // Upload gallery photo
  Future<String?> uploadGalleryPhoto(XFile image, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('users/$userId/gallery/$timestamp.jpg');

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(image.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload gallery photo: $e');
    }
  }
}


