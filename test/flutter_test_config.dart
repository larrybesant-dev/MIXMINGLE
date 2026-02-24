// test/flutter_test_config.dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Guard: ensure tests are executed in a web-capable environment.
  const isWebTest =
      bool.fromEnvironment('FLUTTER_WEB_TEST', defaultValue: false);
  if (!isWebTest) {
    throw UnsupportedError(
      'Tests in this repository require running with --platform=chrome '
      'or with FLUTTER_WEB_TEST=true. Example: flutter test --platform=chrome '
      'or flutter test --platform=chrome --dart-define=FLUTTER_WEB_TEST=true',
    );
  }
  return testMain();
}
