// Ensures all integration tests run on the web platform (Chrome) for JS interop compatibility.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    print('test_config.dart: Forcing integration tests to run on Chrome for web-only dependencies.');
    if (!Platform.environment.containsKey('FLUTTER_TEST_PLATFORM')) {
      print('WARNING: Integration tests must be run with --platform=chrome for web-only code.');
    }
  });
}
