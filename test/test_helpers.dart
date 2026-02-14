/// Test Helpers - Shared utilities, mock data, and fixtures for all tests
///
/// This file provides:
/// - Mock user, friend, group, and message data
/// - Test fixtures for common scenarios
/// - Helper extensions for testing Riverpod providers
/// - Async test utilities
/// - Mocking utilities

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// ============================================================================
// Mock Data Generators
// ============================================================================

/// Mock user object for testing
class MockUser extends Mock implements User {
  final String _uid;
  final String? _email;
  final String? _displayName;
  final String? _photoURL;

  MockUser({
    String uid = 'test-user-123',
    String? email = 'test@example.com',
    String? displayName = 'Test User',
    String? photoURL,
  })  : _uid = uid,
        _email = email,
        _displayName = displayName,
        _photoURL = photoURL;

  @override
  String get uid => _uid;

  @override
  String? get email => _email;

  @override
  String? get displayName => _displayName;

  @override
  String? get photoURL =>
      _photoURL ?? 'https://i.pravatar.cc/150?u=$_uid';

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  bool get phoneNumberVerified => false;

  @override
  UserMetadata get metadata => throw UnimplementedError();

  @override
  String? get phoneNumber => null;

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get refreshToken => 'refresh-token-123';

  @override
  String? get tenantId => null;

  @override
  MultiFactor get multiFactor => throw UnimplementedError();

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'id-token-123';

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      throw UnimplementedError();

  @override
  Future<void> reload() async {}

  @override
  Future<void> delete() async {}

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {}

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {}

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> updatePhotoURL(String? photoURL) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> updateEmail(String newEmail) async {}

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential credential) async {}

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(
    String phoneNumber, [
    RecaptchaVerifier? verificationProcess,
  ]) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<void> linkWithRedirect(AuthProvider provider) async {}

  @override
  Future<User> unlink(String providerId) async => throw UnimplementedError();

  @override
  Future<void> unlinkProvider(String providerId) async {}

  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) async {}
}

/// Creates mock user data with customizable fields
class MockUserData {
  static Map<String, dynamic> user({
    String uid = 'test-user-123',
    String email = 'test@example.com',
    String displayName = 'Test User',
    String? photoURL,
    bool isOnline = true,
  }) =>
      {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL ?? 'https://i.pravatar.cc/150?u=$uid',
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
      };

  static Map<String, dynamic> friend({
    String id = 'friend-123',
    String name = 'Friend Name',
    String avatarUrl = '',
    bool isOnline = true,
    bool isFavorite = false,
    int unreadMessages = 0,
  }) =>
      {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl.isEmpty ? 'https://i.pravatar.cc/150?u=$id' : avatarUrl,
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
        'isFavorite': isFavorite,
        'unreadMessages': unreadMessages,
      };

  static Map<String, dynamic> group({
    String id = 'group-123',
    String name = 'Test Group',
    String description = 'Test group description',
    String avatarUrl = '',
    List<String>? members,
    int unreadCount = 0,
    int? memberCount,
  }) =>
      {
        'id': id,
        'name': name,
        'description': description,
        'avatarUrl':
            avatarUrl.isEmpty ? 'https://i.pravatar.cc/150?u=$id' : avatarUrl,
        'members': members ?? ['test-user-123', 'friend-123'],
        'memberCount': memberCount ?? (members?.length ?? 2),
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 7))
            .toIso8601String(),
        'unreadCount': unreadCount,
      };

  static Map<String, dynamic> chatMessage({
    String senderId = 'test-user-123',
    String senderName = 'Test User',
    String senderAvatar = '',
    String content = 'Test message',
    String type = 'text',
    DateTime? timestamp,
    String? sender,
    bool isOwnMessage = false,
  }) =>
      {
        'senderId': senderId,
        'senderName': senderName,
        'sender': sender ?? senderName,
        'senderAvatar': senderAvatar.isEmpty
            ? 'https://i.pravatar.cc/150?u=$senderId'
            : senderAvatar,
        'content': content,
        'type': type,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        'isOwnMessage': isOwnMessage,
      };

  static Map<String, dynamic> participant({
    String userId = 'participant-123',
    String id = '',
    String? name,
    String userName = 'Participant Name',
    String avatarUrl = '',
    bool isVideoEnabled = true,
    bool isAudioEnabled = true,
    bool isScreenSharing = false,
    bool isMuted = false,
    int unreadCount = 0,
    String cameraApprovalStatus = 'approved',
  }) =>
      {
        'userId': userId,
        'id': id.isNotEmpty ? id : userId,
        'userName': name ?? userName,
        'name': name ?? userName,
        'avatarUrl': avatarUrl.isEmpty
            ? 'https://i.pravatar.cc/150?u=$userId'
            : avatarUrl,
        'isVideoEnabled': isVideoEnabled,
        'isAudioEnabled': isAudioEnabled,
        'isScreenSharing': isScreenSharing,
        'isMuted': isMuted,
        'unreadCount': unreadCount,
        'cameraApprovalStatus': cameraApprovalStatus,
      };
}

// ============================================================================
// Mock Services
// ============================================================================

/// Mock Firebase Auth
class MockFirebaseAuth extends Mock implements FirebaseAuth {
  MockUser? _currentUser;

  @override
  Stream<User?> authStateChanges() async* {
    yield _currentUser;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-email');
    }
    _currentUser = MockUser(email: email, displayName: 'Test User');
    return MockUserCredential(_currentUser!);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-email');
    }
    _currentUser = MockUser(email: email, displayName: 'New User');
    return MockUserCredential(_currentUser!);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  User? get currentUser => _currentUser;

  void setCurrentUser(User? user) {
    _currentUser = user as MockUser?;
  }
}

class MockUserCredential extends Mock implements UserCredential {
  final User _user;

  MockUserCredential(this._user);

  @override
  User get user => _user;

  @override
  AdditionalUserInfo? get additionalUserInfo => null;
}

/// Mock Cloud Firestore
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _data = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return MockCollectionReference(_data, collectionPath);
  }

  void setMockData(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) {
    _data.putIfAbsent(collection, () => {})[documentId] = data;
  }

  Map<String, dynamic> getMockData(String collection, String documentId) {
    return _data[collection]?[documentId] ?? {};
  }
}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _data;
  final String _path;

  MockCollectionReference(this._data, this._path);

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    final docId = 'doc-${DateTime.now().millisecondsSinceEpoch}';
    _data.putIfAbsent(_path, () => {})[docId] = data;
    return MockDocumentReference(_data, _path, docId);
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? documentPath]) {
    return MockDocumentReference(_data, _path, documentPath ?? 'doc-123');
  }

  @override
  Query<Map<String, dynamic>> where(
    Object fieldPath, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return MockQuery(_data, _path);
  }
  // snapshots() is handled by Mock class
}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _data;
  final String _path;
  final String _docId;

  MockDocumentReference(this._data, this._path, this._docId);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final data = _data[_path]?[_docId];
    return MockDocumentSnapshot(_docId, data ?? {}, data != null);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _data.putIfAbsent(_path, () => {})[_docId] = data;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (_data[_path]?[_docId] != null) {
      _data[_path]![_docId]!.addAll(data as Map<String, dynamic>);
    }
  }

  @override
  Future<void> delete() async {
    _data[_path]?.remove(_docId);
  }
  // snapshots() is handled by Mock class
}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _data;
  final String _path;

  MockQuery(this._data, this._path);
  // snapshots() is handled by Mock class
}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  MockQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;

  @override
  int get size => _docs.length;
}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  MockQueryDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;
}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;
  final bool _exists;

  MockDocumentSnapshot(this._id, this._data, this._exists);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _exists ? _data : null;

  @override
  bool get exists => _exists;
}

// ============================================================================
// Test Extensions
// ============================================================================

/// Extension for easier test assertions
extension TestExtensions on WidgetTester {
  /// Finds a widget by type and taps it
  Future<void> tapWidget<T>() async {
    await tap(find.byType(T));
    await pumpAndSettle();
  }

  /// Finds a widget by text and taps it
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pumpAndSettle();
  }

  /// Enters text into a TextField
  Future<void> enterTextToField(String text) async {
    Future<void> origEnterText(WidgetTester self, Finder finder, String text) => self.enterText(finder, text);
    await origEnterText(this, find.byType(TextField), text);
    await pumpAndSettle();
  }

  /// Waits for a widget to appear
  Future<void> waitForWidget<T>({Duration timeout = const Duration(seconds: 5)}) async {
    await pumpAndSettle();
    expect(find.byType(T), findsWidgets);
  }

  /// Scrolls to the bottom of a list
  Future<void> scrollToBottom() async {
    final listFinder = find.byType(ListView);
    await scrollUntilVisible(
      find.byType(ListTile).last,
      500.0,
      scrollable: listFinder,
    );
    await pumpAndSettle();
  }
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Fixture for common test scenarios
class TestFixtures {
  /// Fixture for authenticated user
  static Map<String, dynamic> authenticatedUser() =>
      MockUserData.user(uid: 'test-user-123', email: 'test@example.com');

  /// Fixture for friend list
  static List<Map<String, dynamic>> friendsList() => [
        MockUserData.friend(
          id: 'friend-1',
          name: 'Alice',
          isOnline: true,
          isFavorite: true,
        ),
        MockUserData.friend(
          id: 'friend-2',
          name: 'Bob',
          isOnline: false,
          unreadMessages: 3,
        ),
        MockUserData.friend(
          id: 'friend-3',
          name: 'Charlie',
          isOnline: true,
        ),
      ];

  /// Fixture for groups list
  static List<Map<String, dynamic>> groupsList() => [
        MockUserData.group(
          id: 'group-1',
          name: 'Flutter Devs',
          members: ['test-user-123', 'friend-1', 'friend-2'],
        ),
        MockUserData.group(
          id: 'group-2',
          name: 'Design Team',
          members: ['test-user-123', 'friend-3'],
          unreadCount: 5,
        ),
      ];

  /// Fixture for chat messages
  static List<Map<String, dynamic>> chatMessages() => [
        MockUserData.chatMessage(
          senderId: 'friend-1',
          senderName: 'Alice',
          content: 'Hey, how are you?',
        ),
        MockUserData.chatMessage(
          senderId: 'test-user-123',
          senderName: 'Test User',
          content: 'I\'m doing great!',
        ),
        MockUserData.chatMessage(
          senderId: 'friend-1',
          senderName: 'Alice',
          content: 'Want to join the meeting?',
        ),
      ];

  /// Fixture for video call participants
  static List<Map<String, dynamic>> participants() => [
        MockUserData.participant(
          userId: 'test-user-123',
          userName: 'You',
          isVideoEnabled: true,
          isAudioEnabled: true,
        ),
        MockUserData.participant(
          userId: 'friend-1',
          userName: 'Alice',
          isVideoEnabled: true,
          isAudioEnabled: true,
        ),
        MockUserData.participant(
          userId: 'friend-2',
          userName: 'Bob',
          isVideoEnabled: false,
          cameraApprovalStatus: 'pending',
        ),
      ];
}

// ============================================================================
// Async Test Helpers
// ============================================================================

/// Waits for an async operation with timeout
Future<T> expectAsync<T>(
  Future<T> future, {
  Duration timeout = const Duration(seconds: 5),
}) =>
    future.timeout(
      timeout,
      onTimeout: () =>
          throw TimeoutException('Async operation timed out', timeout),
    );

/// Error state for testing error scenarios
class TestException implements Exception {
  final String message;

  TestException(this.message);

  @override
  String toString() => 'TestException: $message';
}
