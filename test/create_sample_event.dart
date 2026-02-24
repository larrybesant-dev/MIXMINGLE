import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/core/config/firebase_options.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  test('Create sample event', () async {
    print('Creating sample event...');

    try {
      // Create a sample event
      final eventData = {
        'id': 'sample-event-1',
        'title': 'Sample Networking Event',
        'description': 'A sample event to test the events functionality',
        'hostId': 'sample-host-id', // This would normally be a real user ID
        'startTime':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'endTime': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 1, hours: 2))),
        'location': 'Virtual Event',
        'attendees': <String>[],
        'maxAttendees': 50,
        'category': 'Networking',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'imageUrl': '',
        'isPublic': true,
        'createdAt': Timestamp.now(),
      };

      await firestore.collection('events').doc('sample-event-1').set(eventData);
      print('✅ Sample event created successfully!');

      // Verify it was created
      final doc =
          await firestore.collection('events').doc('sample-event-1').get();
      if (doc.exists) {
        print('✅ Event verified in database');
        final data = doc.data()!;
        print('Title: ${data['title']}');
        print('Description: ${data['description']}');
      } else {
        fail('Event was not found after creation');
      }
    } catch (e) {
      print('Error creating sample event: $e');
      fail('Failed to create sample event: $e');
    }
  });
}
