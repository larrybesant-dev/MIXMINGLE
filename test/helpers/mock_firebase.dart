import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mockito/annotations.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
  WriteBatch,
  Transaction,
  FirebaseAuth,
  User,
  UserCredential,
  FirebaseStorage,
  Reference,
  UploadTask,
  TaskSnapshot,
  FirebaseFunctions,
  HttpsCallable,
  HttpsCallableResult,
  FirebaseMessaging,
])
class MockFirebase {}

/// Mock Firestore with in-memory data
class MockFirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _collections = {};

  void addDocument(String collection, String docId, Map<String, dynamic> data) {
    _collections.putIfAbsent(collection, () => {});
    _collections[collection]![docId] = Map.from(data);
  }

  Map<String, dynamic>? getDocument(String collection, String docId) {
    return _collections[collection]?[docId];
  }

  List<Map<String, dynamic>> getCollection(String collection) {
    return _collections[collection]?.values.toList() ?? [];
  }

  void updateDocument(
      String collection, String docId, Map<String, dynamic> data) {
    if (_collections[collection]?.containsKey(docId) ?? false) {
      _collections[collection]![docId]!.addAll(data);
    }
  }

  void deleteDocument(String collection, String docId) {
    _collections[collection]?.remove(docId);
  }

  void clear() {
    _collections.clear();
  }

  List<Map<String, dynamic>> query(
    String collection, {
    String? whereField,
    dynamic whereValue,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) {
    var docs = getCollection(collection);

    // Filter
    if (whereField != null) {
      docs = docs.where((doc) => doc[whereField] == whereValue).toList();
    }

    // Sort
    if (orderByField != null) {
      docs.sort((a, b) {
        final aVal = a[orderByField];
        final bVal = b[orderByField];
        final comparison =
            Comparable.compare(aVal as Comparable, bVal as Comparable);
        return descending ? -comparison : comparison;
      });
    }

    // Limit
    if (limit != null && docs.length > limit) {
      docs = docs.sublist(0, limit);
    }

    return docs;
  }
}

/// Mock Storage Service
class MockStorageService {
  final Map<String, List<int>> _files = {};

  Future<String> uploadFile(String path, List<int> bytes) async {
    _files[path] = bytes;
    return 'https://storage.example.com/$path';
  }

  Future<void> deleteFile(String path) async {
    _files.remove(path);
  }

  bool fileExists(String path) {
    return _files.containsKey(path);
  }

  List<int>? getFile(String path) {
    return _files[path];
  }

  void clear() {
    _files.clear();
  }
}

/// Mock Video Service
class MockVideoService {
  bool isInitialized = false;
  bool isInChannel = false;
  bool isMicMuted = false;
  bool isVideoMuted = false;
  final List<int> remoteUsers = [];

  Future<void> initialize() async {
    await Future.delayed(Duration(milliseconds: 100));
    isInitialized = true;
  }

  Future<void> joinChannel(String channelName, String token, int uid) async {
    await Future.delayed(Duration(milliseconds: 100));
    isInChannel = true;
  }

  Future<void> leaveChannel() async {
    await Future.delayed(Duration(milliseconds: 100));
    isInChannel = false;
    remoteUsers.clear();
  }

  Future<void> toggleMic() async {
    isMicMuted = !isMicMuted;
  }

  Future<void> toggleVideo() async {
    isVideoMuted = !isVideoMuted;
  }

  void simulateUserJoined(int uid) {
    remoteUsers.add(uid);
  }

  void simulateUserLeft(int uid) {
    remoteUsers.remove(uid);
  }

  void dispose() {
    isInitialized = false;
    isInChannel = false;
    remoteUsers.clear();
  }
}
