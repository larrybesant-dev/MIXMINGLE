import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mixvy/features/messaging/providers/messaging_provider.dart';
import 'package:mixvy/shared/widgets/app_shell.dart';
import 'package:mixvy/shared/widgets/messenger_shell_route.dart';

void main() {
  testWidgets('AppShell keeps a docked desktop menu that can be hidden', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [unreadMessageCountProvider.overrideWith((ref) => 0)],
        child: const MaterialApp(
          home: AppShell(selectedIndex: 0, child: SizedBox.expand()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home Feed'), findsOneWidget);
    expect(find.byTooltip('Hide menu'), findsWidgets);

    await tester.tap(find.byTooltip('Hide menu').first);
    await tester.pumpAndSettle();

    expect(find.text('Home Feed'), findsNothing);
    expect(find.byTooltip('Show menu'), findsOneWidget);
  });

  testWidgets('AppShell exposes the new five-tab navigation labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [unreadMessageCountProvider.overrideWith((ref) => 0)],
        child: const MaterialApp(
          home: AppShell(selectedIndex: 0, child: SizedBox.expand()),
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

  testWidgets('Messenger routes accept concrete conversation URLs', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/messages/conversation-123',
      routes: [
        GoRoute(
          path: '/messages/:conversationId',
          builder: (context, state) {
            final routeState = MessengerRouteState.fromGoRouterState(state);
            return Material(
              child: Text(routeState.conversationId ?? 'missing'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('conversation-123'), findsOneWidget);
  });
}
