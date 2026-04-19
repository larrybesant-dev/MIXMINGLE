import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/feed/providers/feed_providers.dart';
import 'package:mixvy/features/social/screens/live_floor_screen.dart';
import 'package:mixvy/models/room_model.dart';

void main() {
  testWidgets(
    'LiveFloorScreen avoids zero-state hero metrics before rooms load',
    (tester) async {
      final controller = StreamController<List<RoomModel>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomsStreamProvider.overrideWith((ref) => controller.stream),
          ],
          child: const MaterialApp(home: LiveFloorScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('Loading live rooms'), findsOneWidget);
      expect(find.text('0 active rooms'), findsNothing);
    },
  );
}
