import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/core/telemetry/app_telemetry.dart';

void main() {
  setUp(() {
    AppTelemetry.reset();
  });

  test('tracks listener counts and mismatch flags', () {
    AppTelemetry.listenerStarted(
      key: 'participants/room-a',
      query: 'rooms/room-a/participants',
      roomId: 'room-a',
      userId: 'user-1',
    );
    AppTelemetry.listenerStarted(
      key: 'participants/room-a',
      query: 'rooms/room-a/participants',
      roomId: 'room-a',
      userId: 'user-1',
    );

    AppTelemetry.updateRoomState(
      roomId: 'room-a',
      joinedUserId: 'user-1',
      roomPhase: 'joined',
      participantCount: 3,
      cameraMismatch: true,
      presenceMismatch: true,
      staleParticipantIds: const <String>{'ghost-user'},
    );

    final state = AppTelemetry.state;
    expect(state.activeListenerCount, 2);
    expect(state.duplicateListenerKeys, contains('participants/room-a'));
    expect(state.cameraMismatch, isTrue);
    expect(state.presenceMismatch, isTrue);
    expect(state.staleParticipantIds, contains('ghost-user'));
    expect(state.recentEvents, isNotEmpty);

    AppTelemetry.listenerStopped(
      key: 'participants/room-a',
      query: 'rooms/room-a/participants',
      roomId: 'room-a',
      userId: 'user-1',
    );
    AppTelemetry.listenerStopped(
      key: 'participants/room-a',
      query: 'rooms/room-a/participants',
      roomId: 'room-a',
      userId: 'user-1',
    );

    expect(AppTelemetry.state.activeListenerCount, 0);
    expect(AppTelemetry.state.duplicateListenerKeys, isEmpty);
  });
}