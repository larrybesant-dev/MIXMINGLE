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
}
