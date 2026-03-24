import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/screens/payments_demo_screen.dart';
import 'test_helpers.dart';
import 'package:mocktail/mocktail.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await testSetup();
  });

  testWidgets('PaymentsDemoScreen renders and shows navigation drawer', (WidgetTester tester) async {
    await tester.pumpWidget(withProviderScope(const MaterialApp(
      home: PaymentsDemoScreen(),
    )));

    // Check for AppBar title
    expect(find.text('Payments Demo'), findsOneWidget);

    // Open the drawer
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    // Check for navigation items
    expect(find.text('Home Feed'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
  }, skip: skipIntegrationTests);
}
