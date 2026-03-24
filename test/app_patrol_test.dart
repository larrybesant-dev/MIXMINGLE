import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mixvy/main.dart' as app;

void main() {
  patrolTest(
    'App launches and navigates main dashboard tabs',
    ($) async {
      // Start the app
      app.main();

      // Wait for UI to fully load
      await $.pumpAndSettle();

      // 👇 Adjust these keys/texts to match your actual UI

      // Example: Tap Home tab
      if ($(#homeTab).exists) {
        await $(#homeTab).tap();
        await $.pumpAndSettle();
      }

      // Example: Tap Matches tab
      if ($(#matchesTab).exists) {
        await $(#matchesTab).tap();
        await $.pumpAndSettle();
      }

      // Example: Tap Profile tab
      if ($(#profileTab).exists) {
        await $(#profileTab).tap();
        await $.pumpAndSettle();
      }

      // Optional: Verify something exists on screen
      expect($(#profileScreen), findsOneWidget);
    },
  );
}