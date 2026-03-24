import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads .env.test and mocks Firebase initialization for tests.
import 'dart:io';
import 'package:path/path.dart' as p;

import 'dart:io';



class MockFirebaseApp extends Mock implements FirebaseApp {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

// Expose mocks for use in test files
final mockAuth = MockFirebaseAuth();
final mockFirestore = MockFirebaseFirestore();

Future<void> testSetup() async {
    // Mock signOut to return a Future<void>
    when(() => mockAuth.signOut()).thenAnswer((_) async => Future.value());
  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue(MockFirebaseApp());
  registerFallbackValue(MockFirebaseAuth());
  registerFallbackValue(MockUserCredential());
  registerFallbackValue(MockUser());
  registerFallbackValue(MockFirebaseFirestore());
  registerFallbackValue(MockDocumentReference());
  registerFallbackValue(MockDocumentSnapshot());
  registerFallbackValue(MockCollectionReference());

  // Mock FirebaseAuth methods
  final mockUser = MockUser();
  final mockUserCredential = MockUserCredential();
  when(() => mockUser.uid).thenReturn('mock-uid');
  when(() => mockUser.email).thenReturn('user@example.com');
  when(() => mockUser.displayName).thenReturn('username');
  when(() => mockUser.photoURL).thenReturn('');
  when(() => mockUserCredential.user).thenReturn(mockUser);
  when(() => mockAuth.currentUser).thenReturn(mockUser);
  when(() => mockAuth.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
      .thenAnswer((_) async => mockUserCredential);
  when(() => mockAuth.createUserWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
      .thenAnswer((_) async => mockUserCredential);
  when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream<User?>.value(mockUser));

  // Mock Firestore methods
  final mockDocRef = MockDocumentReference();
  final mockDocSnap = MockDocumentSnapshot();
  final mockCollection = MockCollectionReference();
  // Setup collection/doc chain
  when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
  when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
  // fetchProfile: doc.get returns a doc with expected data
  when(() => mockDocRef.get()).thenAnswer((_) async {
    when(() => mockDocSnap.exists).thenReturn(true);
    when(() => mockDocSnap.data()).thenReturn({
      'id': 'user123',
      'email': 'user@example.com',
      'username': 'username',
      'avatarUrl': '',
      'coinBalance': 0,
      'membershipLevel': 'basic',
      'followers': <String>[],
      'createdAt': DateTime.now().toIso8601String(),
    });
    return mockDocSnap;
  });
  // updateProfile: doc.update completes
  when(() => mockDocRef.update(any())).thenAnswer((_) async => Future.value());
    // Patch FirebaseAuth and Firestore platform channels only (no .instance assignment)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      (MethodCall methodCall) async {
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/cloud_firestore'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  const MethodChannel firebaseCoreChannel = MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    firebaseCoreChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        return {
          'app': {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake',
              'appId': 'fake',
              'messagingSenderId': 'fake',
              'projectId': 'fake',
            },
          },
          'pluginConstants': {},
        };
      } else if (methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake',
            'appId': 'fake',
            'messagingSenderId': 'fake',
            'projectId': 'fake',
          },
          'pluginConstants': {},
        };
      } else if (methodCall.method == 'FirebaseApp#appNamed') {
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake',
            'appId': 'fake',
            'messagingSenderId': 'fake',
            'projectId': 'fake',
          },
          'pluginConstants': {},
        };
      } else if (methodCall.method == 'FirebaseApp#allApps') {
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake',
              'appId': 'fake',
              'messagingSenderId': 'fake',
              'projectId': 'fake',
            },
            'pluginConstants': {},
          }
        ];
      }
      return null;
    },
  );
}

/// Utility to wrap widget tests in ProviderScope
Widget withProviderScope(Widget child) => ProviderScope(child: child);

/// Utility to skip integration/patrol tests in CI
const bool skipIntegrationTests = bool.fromEnvironment('CI', defaultValue: false);
