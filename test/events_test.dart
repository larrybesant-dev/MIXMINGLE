import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  final fakeFirestore = FakeFirebaseFirestore();

  // Populate fake data for testing
  await fakeFirestore.collection('events').add({
    'title': 'Test Event',
    'hostId': 'testHost',
    'startTime': DateTime.now().toIso8601String(),
  });

  test('Check events collection', () async {
    print('Testing events collection access...');

    try {
      // Try to get all events
      final eventsSnapshot = await fakeFirestore.collection('events').get();
      print('Found ${eventsSnapshot.docs.length} events in database');

      if (eventsSnapshot.docs.isNotEmpty) {
        print('Sample event data:');
        final firstEvent = eventsSnapshot.docs.first.data();
        print('Title: ${firstEvent['title']}');
        print('Host: ${firstEvent['hostId']}');
        print('Start Time: ${firstEvent['startTime']}');
      } else {
        print(
            'No events found in database. This might be why events are not working.');
      }
    } catch (e) {
      print('Error accessing events: $e');
      fail('Failed to access events collection: $e');
    }
  });
}
