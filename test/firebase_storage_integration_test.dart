import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mix_and_mingle/core/config/firebase_options.dart';

void main() {
  const authEmulatorHost = '127.0.0.1';
  const authEmulatorPort = 9099;

  const storageEmulatorHost = '127.0.0.1';
  const storageEmulatorPort = 9199;

  bool firebaseInitialized = false;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // ignore: avoid_print
    print('[storage-test] setUpAll: begin');

    try {
      if (Firebase.apps.isEmpty) {
        // ignore: avoid_print
        print('[storage-test] initializing Firebase app...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 30));
      }

      // ignore: avoid_print
      print(
          '[storage-test] Firebase apps: ${Firebase.apps.map((a) => a.name).toList()}');

      FirebaseAuth.instance.useAuthEmulator(authEmulatorHost, authEmulatorPort);
      FirebaseStorage.instance.useStorageEmulator(
        storageEmulatorHost,
        storageEmulatorPort,
      );

      // ignore: avoid_print
      print('[storage-test] signing in anonymously against Auth emulator...');

      await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 30));

      // ignore: avoid_print
      print(
          '[storage-test] signed in: uid=${FirebaseAuth.instance.currentUser?.uid}');

      firebaseInitialized = true;
    } catch (e) {
      // ignore: avoid_print
      print(
          '[storage-test] SKIP: Firebase initialization failed (emulators not running or platform channels unavailable): $e');
      firebaseInitialized = false;
    }
  });

  tearDownAll(() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      // Ignore errors during teardown if Firebase wasn't initialized
      print('[storage-test] tearDown: $e');
    }
  });

  test('Firebase Storage emulator upload succeeds', () async {
    if (!firebaseInitialized) {
      // ignore: avoid_print
      print('[storage-test] Skipping test - Firebase not initialized');
      return;
    }

    final fileName =
        'health_check_${DateTime.now().millisecondsSinceEpoch}.txt';
    final ref = FirebaseStorage.instance.ref('rooms/health_check/$fileName');

    final Uint8List payload = Uint8List.fromList(
      utf8.encode('Mix & Mingle Storage health check: $fileName'),
    );

    try {
      // ignore: avoid_print
      print('[storage-test] uploading to: ${ref.fullPath}');

      final task = ref.putData(
        payload,
        SettableMetadata(contentType: 'text/plain'),
      );

      final snapshot = await task.whenComplete(() {}).timeout(
            const Duration(seconds: 60),
          );
      expect(snapshot.state, TaskState.success);
      expect(snapshot.ref.fullPath, ref.fullPath);

      // Marker used by check_app_live.ps1
      // (keep this exact string)
      // ignore: avoid_print
      print('Upload successful');

      // ignore: avoid_print
      print('[storage-test] deleting uploaded object...');

      await ref.delete().timeout(const Duration(seconds: 30));

      // ignore: avoid_print
      print('[storage-test] delete complete');
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('❌ FirebaseException: ${e.code} ${e.message}');
      rethrow;
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
