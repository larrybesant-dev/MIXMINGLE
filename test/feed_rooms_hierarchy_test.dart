import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/feed/screens/discovery_feed_screen.dart';
import 'package:mixvy/features/social/screens/live_floor_screen.dart';
import 'package:mixvy/shared/widgets/ui_stability_contract.dart';

void main() {
  testWidgets('home feed surfaces a clear live pulse banner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiscoveryLivePulseBanner(
            key: HomeLayoutV1.livePulseKey,
            liveRoomCount: 3,
            activeListenerCount: 41,
            featuredRoomCount: 2,
          ),
        ),
      ),
    );

    expect(find.byKey(HomeLayoutV1.livePulseKey), findsOneWidget);
    expect(find.text('Live Pulse'), findsOneWidget);
    expect(find.text('3 rooms live'), findsOneWidget);
    expect(find.text('41 listening now'), findsOneWidget);
    expect(find.text('2 featured'), findsOneWidget);
    expect(find.text('Go to Rooms'), findsOneWidget);
    expect(find.text('Live energy is moving right now.'), findsOneWidget);
  });

  testWidgets('rooms tab opens with an entry-focused hero state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveFloorHeroBanner(
            key: RoomLayoutV1.heroKey,
            roomCount: 5,
            listenerCount: 84,
            sortLabel: 'Most Active',
            onQuickJoin: () {},
            onStartRoom: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(RoomLayoutV1.heroKey), findsOneWidget);
    expect(find.byKey(RoomLayoutV1.quickJoinKey), findsOneWidget);
    expect(find.text('Jump into a live room'), findsOneWidget);
    expect(find.text('5 active rooms'), findsOneWidget);
    expect(find.text('84 listening live'), findsOneWidget);
    expect(find.text('Sorted by Most Active'), findsOneWidget);
    expect(find.text('Quick Join'), findsOneWidget);
    expect(find.text('Start a Room'), findsOneWidget);
  });
}
