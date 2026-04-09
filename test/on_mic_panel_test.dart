import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/providers/participant_providers.dart';
import 'package:mixvy/features/room/widgets/on_mic_panel.dart';
import 'package:mixvy/models/room_participant_model.dart';

// Helper: wraps [OnMicPanel] in a [MaterialApp] with the given provider
// override so we don't need Firebase.
Widget _buildPanel({
  required List<RoomParticipantModel> participants,
  String roomId = 'room-1',
  String currentUserId = 'user-1',
}) {
  return ProviderScope(
    overrides: [
      onMicParticipantsProvider(roomId).overrideWith(
        (ref) => Stream.value(participants),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: OnMicPanel(
          roomId: roomId,
          currentUserId: currentUserId,
          displayNameById: {
            for (final p in participants) p.userId: 'User ${p.userId}',
          },
        ),
      ),
    ),
  );
}

RoomParticipantModel _makeParticipant({
  required String userId,
  required String role,
  DateTime? micExpiresAt,
}) {
  final now = DateTime.now();
  return RoomParticipantModel(
    userId: userId,
    role: role,
    joinedAt: now,
    lastActiveAt: now,
    micExpiresAt: micExpiresAt,
  );
}

void main() {
  group('OnMicPanel', () {
    testWidgets('renders nothing when participant list is empty', (tester) async {
      await tester.pumpWidget(_buildPanel(participants: []));
      await tester.pump();
      expect(find.byType(OnMicPanel), findsOneWidget);
      // Panel hides itself when empty.
      expect(find.text('On Mic'), findsNothing);
    });

    testWidgets('renders participant name and host badge for host', (tester) async {
      final host = _makeParticipant(userId: 'host-1', role: 'host');
      await tester.pumpWidget(_buildPanel(
        participants: [host],
        currentUserId: 'other',
      ));
      await tester.pump();

      expect(find.textContaining('User host-1'), findsOneWidget);
      expect(find.text('HOST'), findsOneWidget);
      // Host has no micExpiresAt → no timer badge.
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
    });

    testWidgets('renders countdown badge for stage user with micExpiresAt', (tester) async {
      final stageUser = _makeParticipant(
        userId: 'user-2',
        role: 'stage',
        micExpiresAt: DateTime.now().add(const Duration(seconds: 30)),
      );
      await tester.pumpWidget(_buildPanel(
        participants: [stageUser],
        currentUserId: 'other',
      ));
      await tester.pump();

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      // Should show something like "0:30" or "0:29" depending on timing.
      final timerFinder = find.textContaining(':');
      expect(timerFinder, findsOneWidget);
    });

    testWidgets('does not render countdown badge for stage user without micExpiresAt', (tester) async {
      final stageUser = _makeParticipant(
        userId: 'user-2',
        role: 'stage',
        // No micExpiresAt → unlimited session.
      );
      await tester.pumpWidget(_buildPanel(
        participants: [stageUser],
        currentUserId: 'other',
      ));
      await tester.pump();

      expect(find.byIcon(Icons.timer_outlined), findsNothing);
    });

    testWidgets('timer badge is red when expiry is within 10 seconds', (tester) async {
      final stageUser = _makeParticipant(
        userId: 'user-2',
        role: 'stage',
        micExpiresAt: DateTime.now().add(const Duration(seconds: 5)),
      );
      await tester.pumpWidget(_buildPanel(
        participants: [stageUser],
        currentUserId: 'other',
      ));
      await tester.pump();

      // Icon should use red color (0xFFFF5252).
      final icon = tester.widget<Icon>(find.byIcon(Icons.timer_outlined));
      expect(icon.color, const Color(0xFFFF5252));
    });

    testWidgets('timer badge is orange when expiry is 11..20 seconds away', (tester) async {
      final stageUser = _makeParticipant(
        userId: 'user-2',
        role: 'stage',
        micExpiresAt: DateTime.now().add(const Duration(seconds: 15)),
      );
      await tester.pumpWidget(_buildPanel(
        participants: [stageUser],
        currentUserId: 'other',
      ));
      await tester.pump();

      final icon = tester.widget<Icon>(find.byIcon(Icons.timer_outlined));
      expect(icon.color, const Color(0xFFFF9800));
    });

    testWidgets('timer badge is green when expiry is more than 20 seconds away', (tester) async {
      final stageUser = _makeParticipant(
        userId: 'user-2',
        role: 'stage',
        micExpiresAt: DateTime.now().add(const Duration(seconds: 60)),
      );
      await tester.pumpWidget(_buildPanel(
        participants: [stageUser],
        currentUserId: 'other',
      ));
      await tester.pump();

      final icon = tester.widget<Icon>(find.byIcon(Icons.timer_outlined));
      expect(icon.color, const Color(0xFF4CAF50));
    });

    testWidgets('shows (you) suffix for current user', (tester) async {
      final me = _makeParticipant(userId: 'user-1', role: 'host');
      await tester.pumpWidget(_buildPanel(
        participants: [me],
        currentUserId: 'user-1',
      ));
      await tester.pump();

      expect(find.textContaining('(you)'), findsOneWidget);
    });
  });
}
