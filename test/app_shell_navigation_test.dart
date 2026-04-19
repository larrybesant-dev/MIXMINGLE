import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/messaging/providers/messaging_provider.dart';
import 'package:mixvy/shared/widgets/app_shell.dart';

void main() {
  testWidgets('AppShell exposes the new five-tab navigation labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadMessageCountProvider.overrideWith((ref) => 0),
        ],
        child: const MaterialApp(
          home: AppShell(
            selectedIndex: 0,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
