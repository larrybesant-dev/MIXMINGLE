import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/screens/payments_demo_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mixvy/features/profile/profile_controller.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await testSetup();
    await Firebase.initializeApp();
  });

  testWidgets('PaymentsDemoScreen renders and shows navigation drawer', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(() => ProfileController(firestore: mockFirestore)),
        ],
        child: const MaterialApp(
          home: PaymentsDemoScreen(),
        ),
      ),
    );

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
