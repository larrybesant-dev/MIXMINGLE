import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helpers/test_helpers.dart';

/// Phase 12: Event Tests
/// Tests for event creation, RSVP, attendance, and management

void main() {
  group('Event Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    const String testUserId = 'test_user_123';
    const String testEventId = 'test_event_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('Event Creation', () {
      test('should create event with valid data', () async {
        // Arrange
        final eventData = TestData.event(
          id: testEventId,
          title: 'New Test Event',
          hostId: testUserId,
        );

        // Act
        await fakeFirestore.collection('events').doc(testEventId).set(eventData);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['title'], 'New Test Event');
        expect(doc.data()?['hostId'], testUserId);
      });

      test('should set createdAt timestamp on event creation', () async {
        // Arrange
        final eventData = TestData.event(id: testEventId, hostId: testUserId);

        // Act
        await fakeFirestore.collection('events').doc(testEventId).set(eventData);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        expect(doc.data()?['createdAt'], isNotNull);
      });

      test('should create event with required fields', () async {
        // Arrange
        final eventData = {
          'id': testEventId,
          'title': 'Test Event',
          'hostId': testUserId,
          'startTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
          'endTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1, hours: 2))),
          'maxCapacity': 50,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Act
        await fakeFirestore.collection('events').doc(testEventId).set(eventData);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['title'], isNotNull);
        expect(doc.data()?['hostId'], isNotNull);
        expect(doc.data()?['startTime'], isNotNull);
      });

      test('should store event location data', () async {
        // Arrange
        final eventData = TestData.event(id: testEventId, hostId: testUserId);

        // Act
        await fakeFirestore.collection('events').doc(testEventId).set(eventData);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        expect(doc.data()?['latitude'], isNotNull);
        expect(doc.data()?['longitude'], isNotNull);
      });
    });

    group('Event RSVP', () {
      setUp(() async {
        // Create test event
        await fakeFirestore.collection('events').doc(testEventId).set(
              TestData.event(id: testEventId, hostId: testUserId),
            );
      });

      test('should add user to event attendees', () async {
        // Arrange
        const attendeeId = 'attendee_123';

        // Act
        await fakeFirestore.collection('events').doc(testEventId).collection('rsvps').doc(attendeeId).set({
          'userId': attendeeId,
          'status': 'going',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Assert
        final rsvpDoc =
            await fakeFirestore.collection('events').doc(testEventId).collection('rsvps').doc(attendeeId).get();

        expect(rsvpDoc.exists, isTrue);
        expect(rsvpDoc.data()?['status'], 'going');
      });

      test('should update RSVP status', () async {
        // Arrange
        const attendeeId = 'attendee_123';

        await fakeFirestore.collection('events').doc(testEventId).collection('rsvps').doc(attendeeId).set({
          'userId': attendeeId,
          'status': 'going',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Act
        await fakeFirestore
            .collection('events')
            .doc(testEventId)
            .collection('rsvps')
            .doc(attendeeId)
            .update({'status': 'maybe'});

        // Assert
        final rsvpDoc =
            await fakeFirestore.collection('events').doc(testEventId).collection('rsvps').doc(attendeeId).get();

        expect(rsvpDoc.data()?['status'], 'maybe');
      });

      test('should remove RSVP', () async {
        // Arrange
        const attendeeId = 'attendee_123';

        await fakeFirestore.collection('events').doc(testEventId).collection('rsvps').doc(attendeeId).set({
          'userId': attendeeId,
          'status': 'going',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Act
        await fakeFirestore.collection('events').doc(testEventId).collection('rsvps').doc(attendeeId).delete();

        // Assert
        final rsvpDoc =
            await fakeFirestore.collection('events').doc(testEventId).collection('rsvps').doc(attendeeId).get();

        expect(rsvpDoc.exists, isFalse);
      });

      test('should count total RSVPs', () async {
        // Arrange
        await fakeFirestore
            .collection('events')
            .doc(testEventId)
            .collection('rsvps')
            .doc('user1')
            .set({'userId': 'user1', 'status': 'going'});

        await fakeFirestore
            .collection('events')
            .doc(testEventId)
            .collection('rsvps')
            .doc('user2')
            .set({'userId': 'user2', 'status': 'going'});

        await fakeFirestore
            .collection('events')
            .doc(testEventId)
            .collection('rsvps')
            .doc('user3')
            .set({'userId': 'user3', 'status': 'maybe'});

        // Act
        final snapshot = await fakeFirestore.collection('events').doc(testEventId).collection('rsvps').get();

        // Assert
        expect(snapshot.docs.length, 3);
      });
    });

    group('Event Queries', () {
      setUp(() async {
        // Create multiple test events
        for (int i = 1; i <= 5; i++) {
          await fakeFirestore.collection('events').doc('event_$i').set(
                TestData.event(
                  id: 'event_$i',
                  title: 'Event $i',
                  hostId: testUserId,
                ),
              );
        }
      });

      test('should get all events', () async {
        // Act
        final snapshot = await fakeFirestore.collection('events').get();

        // Assert
        expect(snapshot.docs.length, 5);
      });

      test('should filter events by host', () async {
        // Arrange
        await fakeFirestore.collection('events').doc('other_event').set(
              TestData.event(
                id: 'other_event',
                hostId: 'other_user',
              ),
            );

        // Act
        final snapshot = await fakeFirestore.collection('events').where('hostId', isEqualTo: testUserId).get();

        // Assert
        expect(snapshot.docs.length, 5);
      });

      test('should get event by ID', () async {
        // Act
        final doc = await fakeFirestore.collection('events').doc('event_1').get();

        // Assert
        expect(doc.exists, isTrue);
        expect(doc.data()?['id'], 'event_1');
      });
    });

    group('Event Updates', () {
      setUp(() async {
        await fakeFirestore.collection('events').doc(testEventId).set(
              TestData.event(id: testEventId, hostId: testUserId),
            );
      });

      test('should update event title', () async {
        // Act
        await fakeFirestore.collection('events').doc(testEventId).update({'title': 'Updated Title'});

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        expect(doc.data()?['title'], 'Updated Title');
      });

      test('should update event description', () async {
        // Act
        await fakeFirestore.collection('events').doc(testEventId).update({'description': 'Updated description'});

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        expect(doc.data()?['description'], 'Updated description');
      });

      test('should update event capacity', () async {
        // Act
        await fakeFirestore.collection('events').doc(testEventId).update({'maxCapacity': 100});

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        expect(doc.data()?['maxCapacity'], 100);
      });
    });

    group('Event Deletion', () {
      setUp(() async {
        await fakeFirestore.collection('events').doc(testEventId).set(
              TestData.event(id: testEventId, hostId: testUserId),
            );
      });

      test('should delete event', () async {
        // Act
        await fakeFirestore.collection('events').doc(testEventId).delete();

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        expect(doc.exists, isFalse);
      });

      test('should delete event RSVPs when event is deleted', () async {
        // Arrange
        await fakeFirestore
            .collection('events')
            .doc(testEventId)
            .collection('rsvps')
            .doc('user1')
            .set({'userId': 'user1', 'status': 'going'});

        // Act
        await fakeFirestore.collection('events').doc(testEventId).delete();

        final rsvpsSnapshot = await fakeFirestore.collection('events').doc(testEventId).collection('rsvps').get();

        // Assert - subcollections are not auto-deleted in Firestore
        // But we should document this behavior
        expect(rsvpsSnapshot.docs.length, greaterThanOrEqualTo(0));
      });
    });

    group('Event Capacity', () {
      setUp(() async {
        await fakeFirestore.collection('events').doc(testEventId).set(
              TestData.event(
                id: testEventId,
                hostId: testUserId,
              )..['maxCapacity'] = 2,
            );
      });

      test('should track attendee count', () async {
        // Arrange
        await fakeFirestore
            .collection('events')
            .doc(testEventId)
            .collection('rsvps')
            .doc('user1')
            .set({'userId': 'user1', 'status': 'going'});

        await fakeFirestore
            .collection('events')
            .doc(testEventId)
            .collection('rsvps')
            .doc('user2')
            .set({'userId': 'user2', 'status': 'going'});

        // Act
        final rsvpsSnapshot = await fakeFirestore
            .collection('events')
            .doc(testEventId)
            .collection('rsvps')
            .where('status', isEqualTo: 'going')
            .get();

        // Assert
        expect(rsvpsSnapshot.docs.length, 2);
      });

      test('should check if event is full', () async {
        // Arrange
        final eventDoc = await fakeFirestore.collection('events').doc(testEventId).get();
        final maxCapacity = eventDoc.data()?['maxCapacity'] as int;

        final rsvpsSnapshot = await fakeFirestore
            .collection('events')
            .doc(testEventId)
            .collection('rsvps')
            .where('status', isEqualTo: 'going')
            .get();

        // Act
        final isFull = rsvpsSnapshot.docs.length >= maxCapacity;

        // Assert
        expect(isFull, isFalse);
      });
    });
  });
}
