import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handle(dynamic error) {
    // Add error handling logic here
    // ignore: avoid_print
    debugPrint('Error: $error');
  }
}
