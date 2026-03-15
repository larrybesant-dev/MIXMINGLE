import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// File type enum
enum FileType {
  image,
  video,
  audio,
  document,
  other,
}

/// Shared file model
class SharedFile {
  final String id;
  final String fileName;
  final String fileUrl;
  final FileType fileType;
  final int fileSize; // in bytes
  final String senderId;
  final String senderName;
  final String chatId; // Room or DM ID
  final DateTime uploadedAt;
  final String? thumbnailUrl;

  SharedFile({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.senderId,
    required this.senderName,
    required this.chatId,
    required this.uploadedAt,
    this.thumbnailUrl,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  factory SharedFile.fromMap(Map<String, dynamic> map) {
    return SharedFile(
      id: map['id'] ?? '',
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: FileType.values.firstWhere(
        (e) => e.toString() == 'FileType.${map['fileType']}',
        orElse: () => FileType.other,
      ),
      fileSize: map['fileSize'] ?? 0,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      chatId: map['chatId'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      thumbnailUrl: map['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType.toString().split('.').last,
      'fileSize': fileSize,
      'senderId': senderId,
      'senderName': senderName,
      'chatId': chatId,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

/// Service for file sharing in chats
class FileShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const int maxFileSize = 50 * 1024 * 1024; // 50MB

  /// Upload file to storage and save metadata
  Future<SharedFile> uploadFile({
    required File file,
    required String fileName,
    required String chatId,
    required String senderId,
    required String senderName,
  }) async {
    try {
      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw Exception('File size exceeds 50MB limit');
      }

      // Determine file type
      final fileType = _getFileType(fileName);

      // Create storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef =
          _storage.ref().child('chat_files/$chatId/${timestamp}_$fileName');

      // Upload file
      final uploadTask = await storageRef.putFile(file);
      final fileUrl = await uploadTask.ref.getDownloadURL();

      // Create SharedFile record
      final fileDoc = _firestore.collection('shared_files').doc();
      final sharedFile = SharedFile(
        id: fileDoc.id,
        fileName: fileName,
        fileUrl: fileUrl,
        fileType: fileType,
        fileSize: fileSize,
        senderId: senderId,
        senderName: senderName,
        chatId: chatId,
        uploadedAt: DateTime.now(),
      );

      await fileDoc.set(sharedFile.toMap());

      return sharedFile;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload file from bytes (for web)
  Future<SharedFile> uploadFileFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String chatId,
    required String senderId,
    required String senderName,
  }) async {
    try {
      // Check file size
      if (bytes.length > maxFileSize) {
        throw Exception('File size exceeds 50MB limit');
      }

      // Determine file type
      final fileType = _getFileType(fileName);

      // Create storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef =
          _storage.ref().child('chat_files/$chatId/${timestamp}_$fileName');

      // Upload file
      final uploadTask = await storageRef.putData(bytes);
      final fileUrl = await uploadTask.ref.getDownloadURL();

      // Create SharedFile record
      final fileDoc = _firestore.collection('shared_files').doc();
      final sharedFile = SharedFile(
        id: fileDoc.id,
        fileName: fileName,
        fileUrl: fileUrl,
        fileType: fileType,
        fileSize: bytes.length,
        senderId: senderId,
        senderName: senderName,
        chatId: chatId,
        uploadedAt: DateTime.now(),
      );

      await fileDoc.set(sharedFile.toMap());

      return sharedFile;
    } catch (e) {
      debugPrint('Error uploading file from bytes: $e');
      rethrow;
    }
  }

  /// Get shared files for a chat
  Stream<List<SharedFile>> getChatFiles(String chatId) {
    return _firestore
        .collection('shared_files')
        .where('chatId', isEqualTo: chatId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SharedFile.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  /// Delete a file
  Future<void> deleteFile(String fileId, String fileUrl) async {
    try {
      // Delete from storage
      try {
        final storageRef = _storage.refFromURL(fileUrl);
        await storageRef.delete();
      } catch (e) {
        debugPrint('Error deleting file from storage: $e');
      }

      // Delete metadata
      await _firestore.collection('shared_files').doc(fileId).delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  /// Determine file type from filename
  FileType _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
      return FileType.image;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
      return FileType.video;
    } else if (['mp3', 'wav', 'aac', 'flac', 'm4a'].contains(extension)) {
      return FileType.audio;
    } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt']
        .contains(extension)) {
      return FileType.document;
    } else {
      return FileType.other;
    }
  }
}
