import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/controllers/room_state.dart';

void main() {
  test('RoomState enforces deterministic speaker and chat helpers', () {
    const state = RoomState(
      roomId: 'room-a',
      hostId: 'host-1',
      userIds: <String>['host-1', 'user-1', 'user-2', 'user-3'],
      speakerIds: <String>['host-1', 'user-1', 'user-2', 'user-3'],
    );

    expect(state.canChat('user-1'), isTrue);
    expect(state.canChat('user-99'), isFalse);
    expect(state.isSpeaker('host-1'), isTrue);
    expect(state.canAddSpeaker('user-4'), isFalse);
  });

  test(
    'RoomState camera viewer helpers are driven only by camViewersByUser',
    () {
      const state = RoomState(
        roomId: 'room-a',
        currentUserId: 'me',
        userIds: <String>['me', 'john', 'sarah'],
        camViewersByUser: <String, List<String>>{
          'me': <String>['john'],
          'sarah': <String>['me'],
        },
      );

      expect(state.isWatchingMe(myUserId: 'me', otherUserId: 'john'), isTrue);
      expect(state.isWatchingMe(myUserId: 'me', otherUserId: 'sarah'), isFalse);
      expect(
        state.canViewCamera(targetUserId: 'sarah', viewerUserId: 'me'),
        isTrue,
      );
      expect(state.viewerCountFor('me'), 1);
    },
  );

  test('RoomState authority helpers only allow staff to manage the room', () {
    const state = RoomState(
      roomId: 'room-b',
      hostId: 'host-1',
      participantRolesByUser: <String, String>{
        'host-1': 'host',
        'cohost-1': 'cohost',
        'mod-1': 'moderator',
        'guest-1': 'audience',
      },
    );

    expect(state.canManageStage('host-1'), isTrue);
    expect(state.canManageStage('cohost-1'), isTrue);
    expect(state.canManageStage('mod-1'), isFalse);
    expect(state.canModerate('mod-1'), isTrue);
    expect(state.canManageStage('guest-1'), isFalse);
  });

  test('RoomState only renders users after their join snapshot is stable', () {
    const state = RoomState(
      roomId: 'room-c',
      userIds: <String>['host-1', 'user-1'],
      stableUserIds: <String>['host-1'],
      pendingUserIds: <String>{'user-1'},
      sessionSnapshotsByUser: <String, RoomSessionSnapshot>{
        'host-1': RoomSessionSnapshot(
          userId: 'host-1',
          displayName: 'HostOne',
          role: 'host',
        ),
        'user-1': RoomSessionSnapshot(
          userId: 'user-1',
          displayName: 'VelvetHandle',
          role: 'audience',
        ),
      },
    );

    expect(state.shouldRenderUser('host-1'), isTrue);
    expect(state.shouldRenderUser('user-1'), isFalse);
    expect(state.displayNameFor('host-1'), 'HostOne');
    expect(state.displayNameFor('user-1'), 'VelvetHandle');
  });
}
