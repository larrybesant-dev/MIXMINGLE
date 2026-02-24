import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Setup Firebase for tests
Future<void> setupFirebaseTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Firebase initialization
  // Note: In a real test environment, you'd use Firebase emulators or mock packages
}

/// Create a testable widget with MaterialApp wrapper
Widget createTestableWidget(Widget child,
    {NavigatorObserver? navigatorObserver}) {
  return MaterialApp(
    home: child,
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
  );
}

/// Pump widget and settle
Future<void> pumpAndSettleWidget(
  WidgetTester tester,
  Widget widget, {
  Duration? duration,
}) async {
  await tester.pumpWidget(widget);
  if (duration != null) {
    await tester.pumpAndSettle(duration);
  } else {
    await tester.pumpAndSettle();
  }
}

/// Find text and tap
Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Find widget by key and tap
Future<void> tapByKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Enter text in field
Future<void> enterText(WidgetTester tester, String text,
    {Key? key, Type? type}) async {
  if (key != null) {
    await tester.enterText(find.byKey(key), text);
  } else if (type != null) {
    await tester.enterText(find.byType(type), text);
  }
  await tester.pumpAndSettle();
}

/// Scroll until visible
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = 300.0,
  Finder? scrollable,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: scrollable ?? find.byType(Scrollable).first,
  );
}

/// Wait for condition
Future<void> waitFor(
  Duration duration, {
  bool Function()? condition,
  int maxAttempts = 10,
}) async {
  if (condition == null) {
    await Future.delayed(duration);
    return;
  }

  for (var i = 0; i < maxAttempts; i++) {
    if (condition()) return;
    await Future.delayed(duration);
  }

  throw TimeoutException('Condition not met after ${duration * maxAttempts}');
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Generate test data
class TestData {
  static Map<String, dynamic> userProfile({
    String? uid,
    String? displayName,
    String? email,
  }) {
    return {
      'uid': uid ?? 'test_user_123',
      'displayName': displayName ?? 'Test User',
      'email': email ?? 'test@example.com',
      'bio': 'Test bio',
      'interests': ['music', 'sports', 'travel'],
      'age': 25,
      'gender': 'other',
      'profileImageUrl': 'https://example.com/image.jpg',
      'coins': 100,
      'createdAt': Timestamp.now(),
      'lastSeen': Timestamp.now(),
      'isOnline': true,
    };
  }

  static Map<String, dynamic> event({
    String? id,
    String? title,
    String? hostId,
  }) {
    return {
      'id': id ?? 'event_123',
      'title': title ?? 'Test Event',
      'description': 'Test event description',
      'hostId': hostId ?? 'host_123',
      'startTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 1))),
      'endTime':
          Timestamp.fromDate(DateTime.now().add(Duration(days: 1, hours: 2))),
      'latitude': 37.7749,
      'longitude': -122.4194,
      'maxCapacity': 50,
      'attendees': [],
      'category': 'social',
      'isPublic': true,
      'imageUrl': 'https://example.com/event.jpg',
      'createdAt': Timestamp.now(),
    };
  }

  static Map<String, dynamic> chatMessage({
    String? senderId,
    String? text,
  }) {
    return {
      'senderId': senderId ?? 'sender_123',
      'text': text ?? 'Test message',
      'timestamp': Timestamp.now(),
      'type': 'text',
      'isRead': false,
    };
  }

  static Map<String, dynamic> room({
    String? id,
    String? name,
    String? hostId,
  }) {
    return {
      'id': id ?? 'room_123',
      'name': name ?? 'Test Room',
      'hostId': hostId ?? 'host_123',
      'type': 'voice',
      'isPublic': true,
      'participantIds': [],
      'speakers': [],
      'listeners': [],
      'moderators': [],
      'bannedUsers': [],
      'agoraChannelName': 'test_channel',
      'createdAt': Timestamp.now(),
    };
  }

  static Map<String, dynamic> speedDatingRound({
    String? id,
    String? eventId,
  }) {
    return {
      'id': id ?? 'round_123',
      'eventId': eventId ?? 'event_123',
      'isActive': true,
      'currentRound': 1,
      'totalRounds': 5,
      'roundDuration': 5,
      'participants': [],
      'matches': {},
      'startTime': Timestamp.now(),
      'createdAt': Timestamp.now(),
    };
  }
}
