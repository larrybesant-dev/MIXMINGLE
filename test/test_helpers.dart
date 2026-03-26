import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';



class MockFirebaseApp extends Mock implements FirebaseApp {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
// Removed sealed class mocks for DocumentReference, DocumentSnapshot, and CollectionReference.

// Expose mocks for use in test files
final mockUser = MockUser();
final mockUserCredential = MockUserCredential();
final mockAuth = MockFirebaseAuth();
final mockFirestore = MockFirebaseFirestore();

Future<void> testSetup() async {
  // Removed unused local variable 'currentUser'
  // Removed unsupported StreamController and authStateController logic for test mocks
  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue(MockFirebaseApp());
  registerFallbackValue(MockFirebaseAuth());
  registerFallbackValue(MockUserCredential());
  registerFallbackValue(MockUser());
  registerFallbackValue(MockFirebaseFirestore());

    // Mock FirebaseAuth methods (use top-level mocks)
    when(() => mockUser.uid).thenReturn('mock-uid');
    when(() => mockUser.email).thenReturn('user@example.com');
    when(() => mockUser.displayName).thenReturn('username');
    when(() => mockUser.photoURL).thenReturn('');
    when(() => mockUserCredential.user).thenReturn(mockUser);
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream<User?>.value(mockUser));

  // Mock Firestore methods
  // Setup collection/doc chain
    // Mock Firestore methods
    // Setup collection/doc chain
    // Removed unsupported Firestore/document mocks: MockCollection, MockDocumentReference, MockDocumentSnapshot
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
