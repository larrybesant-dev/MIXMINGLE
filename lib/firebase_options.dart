// File generated manually for MixVy web app
// Based on Firebase web config provided by user

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Add more platforms as needed
    switch (const String.fromEnvironment(
      'FLUTTER_FIRE_PLATFORM',
      defaultValue: 'web',
    )) {
      case 'windows':
        return windows;
      case 'web':
      default:
        return web;
    }
  }

  /// TODO: Move Firebase API key to secure config before production
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB8KXjs0EqnJQdbaKVkX9nwsj07RK2ffM4',
    authDomain: 'mix-and-mingle-v2.firebaseapp.com',
    projectId: 'mix-and-mingle-v2',
    storageBucket: 'mix-and-mingle-v2.firebasestorage.app',
    messagingSenderId: '980846719834',
    appId: '1:980846719834:web:a8981485ee574b25077963',
    measurementId: 'G-XWZLSPYZKY',
  );

  /// TODO: Move Firebase API key to secure config before production
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB8KXjs0EqnJQdbaKVkX9nwsj07RK2ffM4',
    authDomain: 'mix-and-mingle-v2.firebaseapp.com',
    projectId: 'mix-and-mingle-v2',
    storageBucket: 'mix-and-mingle-v2.firebasestorage.app',
    messagingSenderId: '980846719834',
    appId: '1:980846719834:web:17c9f4f34a8fb666077963',
    measurementId: 'G-RE3FC9DMJE',
  );
}
