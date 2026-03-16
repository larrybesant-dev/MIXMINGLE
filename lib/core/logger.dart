import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message) {
    // Use Dart's logging package for production
    // ignore: avoid_print
    // Replace with a proper logger if needed
    // Example: Logger package, Firebase Crashlytics, etc.
    // For now, use debugPrint for development
    debugPrint(message);
  }
}
