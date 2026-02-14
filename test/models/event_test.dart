import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mix_and_mingle/shared/models/event.dart';

void main() {
  group('Event Model Tests', () {
    final startTime = DateTime.now().add(Duration(days: 1));
    final endTime = startTime.add(Duration(hours: 2));

    test('should create Event from map', () {
      final map = {
        'id': 'event123',
        'title': 'Test Event',
        'description': 'Test description',
        'hostId': 'host123',
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'location': 'San Francisco, CA',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'maxCapacity': 50,
        'attendees': ['user1', 'user2'],
        'category': 'social',
        'isPublic': true,
        'imageUrl': 'https://example.com/event.jpg',
        'createdAt': Timestamp.now(),
      };

      final event = Event.fromMap(map);

      expect(event.id, 'event123');
      expect(event.title, 'Test Event');
      expect(event.description, 'Test description');
      expect(event.hostId, 'host123');
      expect(event.maxCapacity, 50);
      expect(event.attendees.length, 2);
      expect(event.category, 'social');
      expect(event.isPublic, true);
    });

    test('should convert Event to map', () {
      final event = Event(
        id: 'event123',
        title: 'Test Event',
        description: 'Test description',
        hostId: 'host123',
        startTime: startTime,
        endTime: endTime,
        location: 'San Francisco, CA',
        latitude: 37.7749,
        longitude: -122.4194,
        maxCapacity: 50,
        attendees: ['user1', 'user2'],
        category: 'social',
        isPublic: true,
        imageUrl: 'https://example.com/event.jpg',
        createdAt: DateTime.now(),
      );

      final map = event.toMap();

      expect(map['id'], 'event123');
      expect(map['title'], 'Test Event');
      expect(map['description'], 'Test description');
      expect(map['hostId'], 'host123');
      expect(map['maxCapacity'], 50);
      expect(map['attendees'], ['user1', 'user2']);
      expect(map['category'], 'social');
      expect(map['isPublic'], true);
    });

    test('should check if event is full', () {
      final event = Event(
        id: 'event123',
        title: 'Test Event',
        description: 'Test description',
        hostId: 'host123',
        startTime: startTime,
        endTime: endTime,
        location: 'San Francisco, CA',
        latitude: 37.7749,
        longitude: -122.4194,
        maxCapacity: 2,
        attendees: ['user1', 'user2'],
        category: 'social',
        isPublic: true,
        imageUrl: 'https://example.com/event.jpg',
        createdAt: DateTime.now(),
      );

      expect(event.isFull, true);

      final eventNotFull = event.copyWith(maxCapacity: 5);
      expect(eventNotFull.isFull, false);
    });

    test('should check if event has started', () {
      final futureEvent = Event(
        id: 'event123',
        title: 'Future Event',
        description: 'Test description',
        hostId: 'host123',
        startTime: DateTime.now().add(Duration(hours: 1)),
        endTime: DateTime.now().add(Duration(hours: 3)),
        location: 'San Francisco, CA',
        latitude: 37.7749,
        longitude: -122.4194,
        maxCapacity: 50,
        attendees: [],
        category: 'social',
        isPublic: true,
        imageUrl: 'https://example.com/event.jpg',
        createdAt: DateTime.now(),
      );

      expect(futureEvent.hasStarted, false);

      final pastEvent = futureEvent.copyWith(
        startTime: DateTime.now().subtract(Duration(hours: 1)),
      );
      expect(pastEvent.hasStarted, true);
    });
  });
}
