import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget test helpers for Mix & Mingle

/// Pump widget with MaterialApp and ProviderScope
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  List<ProviderScope>? overrides,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [],
      child: MaterialApp(
        theme: theme,
        home: widget,
      ),
    ),
  );
}

/// Pump widget and settle (wait for all animations)
Future<void> pumpAndSettleTestWidget(
  WidgetTester tester,
  Widget widget, {
  List<ProviderScope>? overrides,
  ThemeData? theme,
}) async {
  await pumpTestWidget(
    tester,
    widget,
    overrides: overrides,
    theme: theme,
  );
  await tester.pumpAndSettle();
}

/// Find by text and tap
Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Find by icon and tap
Future<void> tapIcon(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await tester.pumpAndSettle();
}

/// Find by key and tap
Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Enter text in field
Future<void> enterText(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Scroll until visible
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder itemFinder,
  Finder scrollableFinder, {
  double delta = 300,
}) async {
  await tester.scrollUntilVisible(
    itemFinder,
    delta,
    scrollable: scrollableFinder,
  );
  await tester.pumpAndSettle();
}

/// Expect to find widget
void expectToFind(Finder finder, {int count = 1}) {
  expect(finder, findsNWidgets(count));
}

/// Expect not to find widget
void expectNotToFind(Finder finder) {
  expect(finder, findsNothing);
}

/// Expect to find text
void expectText(String text, {int count = 1}) {
  expectToFind(find.text(text), count: count);
}

/// Expect to find icon
void expectIcon(IconData icon, {int count = 1}) {
  expectToFind(find.byIcon(icon), count: count);
}

/// Wait for widget to appear
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    if (tester.any(finder)) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  throw TimeoutException('Timeout waiting for $finder', timeout);
}

/// Wait for text to appear
Future<void> waitForText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  await waitFor(tester, find.text(text), timeout: timeout);
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}
