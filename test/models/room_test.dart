import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/shared/models/room.dart';

void main() {
  group('Room', () {
    test('fromMap handles voice-room fields and defaults', () {
      final map = {
        'id': 'room123',
        'name': 'Test Room',
        'hostId': 'host123',
        'participantIds': ['user1', 'user2'],
        'isActive': true,
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'title': 'Stage',
        'description': 'desc',
        'tags': ['tag1'],
        'privacy': 'public',
        'status': 'live',
        'category': 'general',
        'hostName': 'Host',
        'thumbnailUrl': null,
        'viewerCount': 10,
        'isLive': true,
        'roomType': 'voice',
        'moderators': ['host123'],
        'bannedUsers': ['banned1'],
        'agoraChannelName': 'chan',
        'speakers': ['host123'],
        'listeners': ['user2'],
        'allowSpeakerRequests': false,
        'turnBased': true,
        'currentSpeakerId': 'host123',
        'speakerQueue': ['user2'],
        'raisedHands': ['user2'],
        'turnDurationSeconds': 120,
      };

      final room = Room.fromMap(map);

      expect(room.id, 'room123');
      expect(room.roomType, RoomType.voice);
      expect(room.moderators, contains('host123'));
      expect(room.bannedUsers, contains('banned1'));
      expect(room.turnBased, isTrue);
      expect(room.turnDurationSeconds, 120);
      expect(room.currentSpeakerId, 'host123');
    });

    test('toMap preserves core fields', () {
      final room = Room(
        id: 'room999',
        name: 'Voice Hangout',
        hostId: 'host1',
        participantIds: const ['host1', 'user1'],
        isActive: true,
        createdAt: DateTime(2024, 2, 2),
        title: 'Voice Hangout',
        description: 'desc',
        tags: const ['fun'],
        privacy: 'public',
        status: 'live',
        category: 'general',
        hostName: 'Host',
        thumbnailUrl: null,
        viewerCount: 5,
        isLive: true,
        roomType: RoomType.voice,
        moderators: const ['host1'],
        bannedUsers: const [],
        agoraChannelName: 'chan',
        speakers: const ['host1'],
        listeners: const ['user1'],
        allowSpeakerRequests: true,
        turnBased: false,
        currentSpeakerId: null,
        speakerQueue: const [],
        raisedHands: const [],
        turnDurationSeconds: 90,
      );

      final map = room.toMap();

      expect(map['id'], 'room999');
      expect(map['roomType'], 'voice');
      expect(map['speakers'], ['host1']);
      expect(map['listeners'], ['user1']);
      expect(map['turnDurationSeconds'], 90);
      expect(map['createdAt'], isA<String>());
    });
  });
}
