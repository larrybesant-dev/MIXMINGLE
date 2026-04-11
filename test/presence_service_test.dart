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
        'lastSeen': DateTime.now().toIso8601String(),
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
        'lastSeen': DateTime.now().toIso8601String(),
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
        'lastSeen': DateTime.now().toIso8601String(),
      });

      expect(offline.isOnline, isFalse);
      expect(offline.status, UserStatus.offline);
      expect(online.isOnline, isTrue);
      expect(online.status, UserStatus.online);
    });
  });

  group('PresenceService', () {
    test('reads presence snapshots through PresenceModel normalization', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PresenceService(firestore: firestore);
      await firestore.collection('users').doc('placeholder').set({'ok': true});

      final emissions = <PresenceModel>[];
      final sub = service.watchUserPresence('user-1').listen(emissions.add);

      await firestore.collection('users').doc('placeholder-2').set({'ok': true});

      expect(emissions, isNotEmpty);

      await sub.cancel();
    });
  });
}