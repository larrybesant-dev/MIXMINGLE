import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/controllers/room_state.dart';
import 'package:mixvy/models/room_participant_model.dart';

void main() {
  group('RoomStateMachine', () {
    test('resolves lifecycle transitions consistently', () {
      expect(
        RoomStateMachine.resolveLifecycleState(
          roomId: 'room-a',
          phase: LiveRoomPhase.joining,
          isHydrated: false,
          currentUserId: 'user-1',
        ),
        RoomLifecycleState.hydrating,
      );

      expect(
        RoomStateMachine.resolveLifecycleState(
          roomId: 'room-a',
          phase: LiveRoomPhase.joined,
          isHydrated: true,
          currentUserId: 'user-1',
        ),
        RoomLifecycleState.active,
      );

      expect(
        RoomStateMachine.resolveLifecycleState(
          roomId: 'room-a',
          phase: LiveRoomPhase.error,
          isHydrated: false,
          currentUserId: 'user-1',
          errorMessage: 'sync failed',
        ),
        RoomLifecycleState.degraded,
      );

      expect(
        RoomStateMachine.resolveLifecycleState(
          roomId: 'room-a',
          phase: LiveRoomPhase.leaving,
          isHydrated: true,
          currentUserId: 'user-1',
        ),
        RoomLifecycleState.ended,
      );
    });

    test('uses a single source of truth for host and role resolution', () {
      final participants = [
        RoomParticipantModel(
          userId: 'host-1',
          role: 'owner',
          joinedAt: DateTime(2026, 1, 1),
          lastActiveAt: DateTime(2026, 1, 1),
        ),
        RoomParticipantModel(
          userId: 'user-2',
          role: 'cohost',
          joinedAt: DateTime(2026, 1, 1),
          lastActiveAt: DateTime(2026, 1, 1),
        ),
      ];

      final hostId = RoomStateMachine.resolveHostId(
        roomDoc: const <String, dynamic>{},
        participants: participants,
      );

      expect(hostId, 'host-1');
      expect(
        RoomStateMachine.resolveParticipantRole(
          userId: 'host-1',
          hostId: hostId,
          participantRolesByUser: const {
            'host-1': 'owner',
            'user-2': 'cohost',
          },
        ),
        'owner',
      );
      expect(
        RoomStateMachine.resolveParticipantRole(
          userId: 'user-2',
          hostId: hostId,
          participantRolesByUser: const {
            'host-1': 'owner',
            'user-2': 'cohost',
          },
        ),
        'cohost',
      );
    });

    test('keeps authority gated until the room is hydrated', () {
      const state = RoomState(
        phase: LiveRoomPhase.joining,
        lifecycleState: RoomLifecycleState.hydrating,
        roomId: 'room-a',
        currentUserId: 'host-1',
        hostId: 'host-1',
        pendingUserIds: {'host-1'},
      );

      expect(state.lifecycleState, RoomLifecycleState.hydrating);
      expect(
        state.canExecute(RoomAction.manageRoom, userId: 'host-1'),
        isFalse,
      );
    });

    test('resolves audio authority from the room state machine', () {
      expect(
        RoomStateMachine.resolveAudioState(
          roomState: RoomLifecycleState.hydrating,
          isHost: false,
          isCohost: false,
          micRequested: true,
          hasMicPermission: true,
        ),
        RoomAudioState.muted,
      );

      expect(
        RoomStateMachine.resolveAudioState(
          roomState: RoomLifecycleState.active,
          isHost: false,
          isCohost: false,
          micRequested: false,
          hasMicPermission: false,
        ),
        RoomAudioState.denied,
      );

      expect(
        RoomStateMachine.resolveAudioState(
          roomState: RoomLifecycleState.active,
          isHost: true,
          isCohost: false,
          micRequested: false,
          hasMicPermission: true,
        ),
        RoomAudioState.speaking,
      );

      expect(
        RoomStateMachine.resolveAudioState(
          roomState: RoomLifecycleState.active,
          isHost: false,
          isCohost: true,
          micRequested: false,
          hasMicPermission: true,
        ),
        RoomAudioState.cohostSpeaking,
      );

      expect(
        RoomStateMachine.resolveAudioState(
          roomState: RoomLifecycleState.active,
          isHost: false,
          isCohost: false,
          micRequested: true,
          hasMicPermission: true,
        ),
        RoomAudioState.requestingMic,
      );
    });
  });
}
