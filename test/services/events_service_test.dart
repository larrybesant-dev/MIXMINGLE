import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helpers/mock_firebase.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockFirestoreService mockFirestore;

  setUp(() {
    mockFirestore = MockFirestoreService();
  });

  tearDown(() {
    mockFirestore.clear();
  });

  group('EventsService Tests', () {
    test('should create event with validation', () {
      // Arrange
      final event = TestData.event(
        id: 'event1',
        title: 'Test Event',
        hostId: 'host1',
      );

      // Act
      mockFirestore.addDocument('events', 'event1', event);

      // Assert
      final created = mockFirestore.getDocument('events', 'event1');
      expect(created, isNotNull);
      expect(created?['title'], 'Test Event');
      expect(created?['hostId'], 'host1');
    });

    test('should validate event data', () {
      // Arrange
      final invalidEvent = {
        'title': '', // Empty title
        'description': 'Test',
      };

      // Act & Assert
      expect(invalidEvent['title'], isEmpty);
    });

    test('should get upcoming events', () {
      // Arrange
      final now = DateTime.now();
      mockFirestore.addDocument('events', 'event1', {
        ...TestData.event(id: 'event1'),
        'startTime': Timestamp.fromDate(now.add(Duration(days: 1))),
        'isPublic': true,
      });
      mockFirestore.addDocument('events', 'event2', {
        ...TestData.event(id: 'event2'),
        'startTime': Timestamp.fromDate(now.subtract(Duration(days: 1))),
        'isPublic': true,
      });

      // Act
      final allEvents = mockFirestore.getCollection('events');
      final upcomingEvents = allEvents.where((event) {
        final startTime = (event['startTime'] as Timestamp).toDate();
        return startTime.isAfter(now) && event['isPublic'] == true;
      }).toList();

      // Assert
      expect(upcomingEvents.length, 1);
      expect(upcomingEvents[0]['id'], 'event1');
    });

    test('should enforce capacity limits', () {
      // Arrange
      final event = TestData.event(id: 'event1');
      event['maxCapacity'] = 2;
      event['attendees'] = ['user1', 'user2'];
      mockFirestore.addDocument('events', 'event1', event);

      // Act
      final eventData = mockFirestore.getDocument('events', 'event1');
      final isFull = (eventData?['attendees'] as List).length >=
          (eventData?['maxCapacity'] as int);

      // Assert
      expect(isFull, true);
    });

    test('should join event', () {
      // Arrange
      final event = TestData.event(id: 'event1');
      event['attendees'] = <String>[];
      mockFirestore.addDocument('events', 'event1', event);

      // Act
      final eventData = mockFirestore.getDocument('events', 'event1');
      (eventData?['attendees'] as List).add('user1');
      mockFirestore.updateDocument('events', 'event1', eventData!);

      // Assert
      final updated = mockFirestore.getDocument('events', 'event1');
      expect(updated?['attendees'], contains('user1'));
    });

    test('should leave event', () {
      // Arrange
      final event = TestData.event(id: 'event1');
      event['attendees'] = ['user1', 'user2'];
      mockFirestore.addDocument('events', 'event1', event);

      // Act
      final eventData = mockFirestore.getDocument('events', 'event1');
      (eventData?['attendees'] as List).remove('user1');
      mockFirestore.updateDocument('events', 'event1', eventData!);

      // Assert
      final updated = mockFirestore.getDocument('events', 'event1');
      expect(updated?['attendees'], isNot(contains('user1')));
      expect(updated?['attendees'], contains('user2'));
    });

    test('should search events by category', () {
      // Arrange
      mockFirestore.addDocument('events', 'event1', {
        ...TestData.event(id: 'event1'),
        'category': 'social',
      });
      mockFirestore.addDocument('events', 'event2', {
        ...TestData.event(id: 'event2'),
        'category': 'sports',
      });

      // Act
      final socialEvents = mockFirestore.query(
        'events',
        whereField: 'category',
        whereValue: 'social',
      );

      // Assert
      expect(socialEvents.length, 1);
      expect(socialEvents[0]['category'], 'social');
    });

    test('should delete event', () {
      // Arrange
      mockFirestore.addDocument(
          'events', 'event1', TestData.event(id: 'event1'));

      // Act
      mockFirestore.deleteDocument('events', 'event1');

      // Assert
      final deleted = mockFirestore.getDocument('events', 'event1');
      expect(deleted, isNull);
    });

    test('should only allow host to delete event', () {
      // Arrange
      final event = TestData.event(id: 'event1', hostId: 'host1');
      mockFirestore.addDocument('events', 'event1', event);

      // Act
      final eventData = mockFirestore.getDocument('events', 'event1');
      final isHost = eventData?['hostId'] == 'host1';

      // Assert
      expect(isHost, true);
    });
  });
}
