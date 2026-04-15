import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/dashboard/widgets/social_pulse_section.dart';
import 'package:mixvy/models/social_activity_model.dart';

void main() {
  testWidgets('SocialPulseSection renders activity items and CTA labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SocialPulseSection(
            activities: [
              SocialActivity(
                id: 'a1',
                userId: 'u1',
                type: 'joined_room',
                timestamp: DateTime(2026, 4, 12, 21, 0),
                metadata: {'roomName': 'Velvet Lounge'},
              ),
              SocialActivity(
                id: 'a2',
                userId: 'u1',
                type: 'followed_user',
                timestamp: DateTime(2026, 4, 12, 20, 45),
                metadata: {'targetUsername': '@midnightmuse'},
              ),
            ],
            onOpenRooms: _noop,
            onOpenDiscover: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Social Pulse'), findsOneWidget);
    expect(find.text('Velvet Lounge'), findsOneWidget);
    expect(find.text('@midnightmuse'), findsOneWidget);
    expect(find.text('Join a room'), findsOneWidget);
    expect(find.text('Find people'), findsOneWidget);
  });

  testWidgets('SocialPulseSection shows quiet-state prompt when no activity exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SocialPulseSection(
            activities: [],
            onOpenRooms: _noop,
            onOpenDiscover: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Your circle is quiet right now.'), findsOneWidget);
    expect(find.text('Start the vibe'), findsOneWidget);
  });
}

void _noop() {}
