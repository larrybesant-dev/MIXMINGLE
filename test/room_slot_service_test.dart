import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/providers/room_slot_provider.dart';

void main() {
  group('RoomSlotService', () {
    late FakeFirebaseFirestore firestore;
    late RoomSlotService service;

    const roomId = 'room-1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = RoomSlotService(firestore);
    });

    // Helpers ------------------------------------------------------------------

    Future<String?> slotOwner(String slotId) async {
      final doc = await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('slots')
          .doc(slotId)
          .get();
      if (!doc.exists) return null;
      return doc.data()?['userId'] as String?;
    }

    Future<bool?> participantCamOn(String userId) async {
      final doc = await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('participants')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return doc.data()?['camOn'] as bool?;
    }

    // -------------------------------------------------------------------------

    test('claimSlot returns a slot id and writes userId to Firestore', () async {
      final slotId = await service.claimSlot(roomId, 'user-a', maxBroadcasters: 3);

      expect(slotId, isNotNull);
      expect(await slotOwner(slotId!), 'user-a');
      expect(await participantCamOn('user-a'), isTrue);
    });

    test('claimSlot returns null when all slots are occupied', () async {
      // Fill 2 of 2 slots.
      await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('slots')
          .doc('1')
          .set({'userId': 'user-x'});
      await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('slots')
          .doc('2')
          .set({'userId': 'user-y'});

      final slotId = await service.claimSlot(roomId, 'user-a', maxBroadcasters: 2);

      expect(slotId, isNull);
      // participant doc should not be written when claim fails.
      expect(await participantCamOn('user-a'), isNull);
    });

    test('claimSlot is idempotent — re-claiming own slot returns same id', () async {
      final first = await service.claimSlot(roomId, 'user-a', maxBroadcasters: 3);
      final second = await service.claimSlot(roomId, 'user-a', maxBroadcasters: 3);

      expect(first, isNotNull);
      expect(second, equals(first));
    });

    test('releaseSlot deletes the slot doc and sets camOn=false', () async {
      final slotId = await service.claimSlot(roomId, 'user-a', maxBroadcasters: 3);
      expect(slotId, isNotNull);

      await service.releaseSlot(roomId, 'user-a');

      // Slot document should be deleted so a new user can create it fresh.
      final doc = await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('slots')
          .doc(slotId)
          .get();
      expect(doc.exists, isFalse);
      expect(await participantCamOn('user-a'), isFalse);
    });

    test('releaseSlot allows another user to claim the freed slot', () async {
      await service.claimSlot(roomId, 'user-a', maxBroadcasters: 1);
      await service.releaseSlot(roomId, 'user-a');

      final slotId = await service.claimSlot(roomId, 'user-b', maxBroadcasters: 1);
      expect(slotId, isNotNull);
      expect(await slotOwner(slotId!), 'user-b');
    });

    test('claimSlot rejects blank roomId or userId gracefully', () async {
      expect(await service.claimSlot('', 'user-a'), isNull);
      expect(await service.claimSlot('  ', 'user-a'), isNull);
      expect(await service.claimSlot(roomId, ''), isNull);
      expect(await service.claimSlot(roomId, '  '), isNull);
    });

    test('releaseSlot does nothing for blank inputs without throwing', () async {
      // Must not throw.
      await service.releaseSlot('', 'user-a');
      await service.releaseSlot(roomId, '');
    });

    test('concurrent claims respect maxBroadcasters limit', () async {
      // Simulate two sequential claims against a 1-slot room.
      // (fake_cloud_firestore does not execute true concurrent transactions,
      // but we verify that the second claim after the first is rejected.)
      final first = await service.claimSlot(roomId, 'user-a', maxBroadcasters: 1);
      final second = await service.claimSlot(roomId, 'user-b', maxBroadcasters: 1);

      expect(first, isNotNull);
      expect(second, isNull);
    });
  });
}
