import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> participantIds;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.startTime,
    required this.endTime,
    required this.participantIds,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      organizerId: data['organizerId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      participantIds: List<String>.from(data['participantIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'participantIds': participantIds,
    };
  }
}
