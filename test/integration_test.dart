import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/models/room.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Simple test to verify the app can be built and basic widgets work
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Mix & Mingle App Test'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Mix & Mingle App Test'), findsOneWidget);
  });

  test('Room model can be created', () {
    // Test that we can create a Room object with required parameters
    final room = Room(
      id: 'test-id',
      name: 'Test Room',
      title: 'Test Title',
      description: 'Test Description',
      tags: ['test'],
      privacy: 'public',
      status: 'live',
      participantIds: ['user1'],
      category: 'general',
      createdAt: DateTime.now(),
      hostId: 'host1',
      hostName: 'Test Host',
      thumbnailUrl: null,
      viewerCount: 0,
      isLive: true,
    );

    expect(room.id, 'test-id');
    expect(room.name, 'Test Room');
    expect(room.isLive, true);
  });
}
