// Corrected FirebaseOptions for MixVy
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    const platform = String.fromEnvironment(
      'FLUTTER_FIRE_PLATFORM',
      defaultValue: 'web',
    );

    switch (platform) {
      case 'windows':
        return windows;
      case 'web':
      default:
        return web;
    }
  }

  static String _requiredEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required Firebase config value: $key');
    }
    return value;
  }

  /// FirebaseOptions for web
  static FirebaseOptions get web => FirebaseOptions(
      apiKey: _requiredEnv('FIREBASE_API_KEY_WEB'),
        authDomain: 'mix-and-mingle-v2.firebaseapp.com',
        projectId: 'mix-and-mingle-v2',
        storageBucket: 'mix-and-mingle-v2.firebasestorage.app',
        messagingSenderId: '980846719834',
        appId: '1:980846719834:web:fbcdf5051c55d691077963',
        measurementId: 'G-BN784E6ZJY',
      );

  /// FirebaseOptions for Windows
  static FirebaseOptions get windows => FirebaseOptions(
      apiKey: _requiredEnv('FIREBASE_API_KEY_WINDOWS'),
        authDomain: 'mix-and-mingle-v2.firebaseapp.com',
        projectId: 'mix-and-mingle-v2',
        storageBucket: 'mix-and-mingle-v2.firebasestorage.app',
        messagingSenderId: '980846719834',
        appId: '1:980846719834:web:17c9f4f34a8fb666077963',
        measurementId: 'G-RE3FC9DMJE',
      );
}