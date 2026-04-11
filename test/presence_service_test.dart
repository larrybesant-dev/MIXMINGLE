import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/models/presence_model.dart';
import 'package:mixvy/services/presence_service.dart';

void main() {
  group('PresenceModel.fromJson', () {
    test('reads current schema fields', () {
      final model = PresenceModel.fromJson({
        'userId': 'user-1',
        'isOnline': true,
        'status': 'online',
        'inRoom': 'room-a',
      });

      expect(model.userId, 'user-1');
      expect(model.isOnline, isTrue);
      expect(model.status, UserStatus.online);
      expect(model.inRoom, 'room-a');
    });

    test('reads legacy schema fields', () {
      final model = PresenceModel.fromJson({
        'userId': 'user-2',
        'online': true,
        'userStatus': 'away',
        'roomId': 'room-b',
      });

      expect(model.userId, 'user-2');
      expect(model.isOnline, isTrue);
      expect(model.status, UserStatus.away);
      expect(model.inRoom, 'room-b');
    });

    test('treats missing online fields as offline unless status says otherwise', () {
      final offline = PresenceModel.fromJson({'userId': 'user-3'});
      final online = PresenceModel.fromJson({
        'userId': 'user-4',
        'status': 'online',
      });

      expect(offline.isOnline, isFalse);
      expect(offline.status, UserStatus.offline);
      expect(online.isOnline, isTrue);
      expect(online.status, UserStatus.online);
    });
  });

  group('PresenceService', () {
    test('writes current and legacy-compatible presence fields', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PresenceService(firestore: firestore);

      await service.setStatus('user-1', UserStatus.online);
      await service.setInRoom('user-1', 'room-a');

      final snapshot =
          await firestore.collection('presence').doc('user-1').get();
      final data = snapshot.data();

      expect(data, isNotNull);
      expect(data!['isOnline'], isTrue);
      expect(data['online'], isTrue);
      expect(data['status'], 'online');
      expect(data['userStatus'], 'online');
      expect(data['inRoom'], 'room-a');
      expect(data['roomId'], 'room-a');
    });
  });
}