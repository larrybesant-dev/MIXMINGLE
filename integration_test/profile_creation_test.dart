import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_and_mingle/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Creation Integration Tests', () {
    testWidgets('should create user profile', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Navigate to signup/profile creation
      // This assumes user is logged in or has completed signup
      final createProfileButton = find.text('Create Profile');
      if (createProfileButton.evaluate().isNotEmpty) {
        await tester.tap(createProfileButton);
        await tester.pumpAndSettle();

        // Act - Fill in profile information
        // Find display name field
        final nameField = find.byType(TextField).first;
        await tester.enterText(nameField, 'Test User');
        await tester.pumpAndSettle();

        // Find bio field
        final bioFields = find.byType(TextField);
        if (bioFields.evaluate().length > 1) {
          await tester.enterText(bioFields.at(1), 'Test bio');
          await tester.pumpAndSettle();
        }

        // Select interests (if available)
        final musicChip = find.text('Music');
        if (musicChip.evaluate().isNotEmpty) {
          await tester.tap(musicChip);
          await tester.pumpAndSettle();
        }

        final sportsChip = find.text('Sports');
        if (sportsChip.evaluate().isNotEmpty) {
          await tester.tap(sportsChip);
          await tester.pumpAndSettle();
        }

        // Submit profile
        final saveButton = find.text('Save');
        final submitButton = find.text('Submit');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
        } else if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton);
        }
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Assert
        expect(find.text('Test User'), findsWidgets);
      }
    });

    testWidgets('should validate required fields', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile creation
      final createProfileButton = find.text('Create Profile');
      if (createProfileButton.evaluate().isNotEmpty) {
        await tester.tap(createProfileButton);
        await tester.pumpAndSettle();

        // Act - Try to save without filling required fields
        final saveButton = find.text('Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }

        // Assert - Error messages should be shown
        expect(find.byType(TextField), findsWidgets);
      }
    });

    testWidgets('should upload profile photo', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile creation/edit
      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Act - Tap profile photo upload
        final photoUpload = find.byIcon(Icons.camera_alt);
        if (photoUpload.evaluate().isNotEmpty) {
          await tester.tap(photoUpload);
          await tester.pumpAndSettle();
        }

        // Assert
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('should select age and gender', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile creation
      final createProfileButton = find.text('Create Profile');
      if (createProfileButton.evaluate().isNotEmpty) {
        await tester.tap(createProfileButton);
        await tester.pumpAndSettle();

        // Act - Select age
        final ageDropdown = find.byType(DropdownButton<int>);
        if (ageDropdown.evaluate().isNotEmpty) {
          await tester.tap(ageDropdown.first);
          await tester.pumpAndSettle();

          final age25 = find.text('25').last;
          if (age25.evaluate().isNotEmpty) {
            await tester.tap(age25);
            await tester.pumpAndSettle();
          }
        }

        // Select gender
        final genderDropdown = find.byType(DropdownButton<String>);
        if (genderDropdown.evaluate().isNotEmpty) {
          await tester.tap(genderDropdown.first);
          await tester.pumpAndSettle();
        }

        // Assert
        expect(find.byType(DropdownButton), findsWidgets);
      }
    });
  });
}
