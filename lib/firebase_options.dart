// Corrected FirebaseOptions for MixVy
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

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

  /// FirebaseOptions for web
  // Note: apiKey is public and safe to hardcode in web apps
  static FirebaseOptions get web => FirebaseOptions(
      apiKey: 'AIzaSyB8KXjs0EqnJQdbaKVkX9nwsj07RK2ffM4',
        authDomain: 'mix-and-mingle-v2.firebaseapp.com',
        projectId: 'mix-and-mingle-v2',
        storageBucket: 'mix-and-mingle-v2.firebasestorage.app',
        messagingSenderId: '980846719834',
        appId: '1:980846719834:web:fbcdf5051c55d691077963',
        measurementId: 'G-BN784E6ZJY',
      );

  /// FirebaseOptions for Windows
  static FirebaseOptions get windows => FirebaseOptions(
      apiKey: 'AIzaSyB8KXjs0EqnJQdbaKVkX9nwsj07RK2ffM4',
        authDomain: 'mix-and-mingle-v2.firebaseapp.com',
        projectId: 'mix-and-mingle-v2',
        storageBucket: 'mix-and-mingle-v2.firebasestorage.app',
        messagingSenderId: '980846719834',
        appId: '1:980846719834:web:17c9f4f34a8fb666077963',
        measurementId: 'G-RE3FC9DMJE',
      );
}