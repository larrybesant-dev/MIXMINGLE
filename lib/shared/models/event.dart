import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String hostId;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final List<String> attendees;
  final int maxCapacity;
  final String category;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final bool isPublic;
  final bool isOnline;
  final String? roomId;
  final int attendeesCount;
  final int interestedCount;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.hostId,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.attendees,
    required this.maxCapacity,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.isPublic,
    this.isOnline = false,
    this.roomId,
    this.attendeesCount = 0,
    this.interestedCount = 0,
    required this.createdAt,
  });

  // Convenience getters for backward compatibility
  List<String> get attendeeIds => attendees;
  String get creatorId => hostId;
  int get maxAttendees => maxCapacity;
  DateTime get date => startTime;
  int get attendeeCount => attendeesCount;
  bool get isFull => attendees.length >= maxCapacity;
  bool get hasStarted => DateTime.now().isAfter(startTime);

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Event',
      description: map['description'] as String? ?? '',
      hostId: map['hostId'] as String? ?? '',
      startTime: map['startTime'] != null
          ? (map['startTime'] is Timestamp
              ? (map['startTime'] as Timestamp).toDate()
              : DateTime.tryParse(map['startTime'].toString()) ?? DateTime.now())
          : DateTime.now(),
      endTime: map['endTime'] != null
          ? (map['endTime'] is Timestamp
              ? (map['endTime'] as Timestamp).toDate()
              : DateTime.tryParse(map['endTime'].toString()) ?? DateTime.now().add(const Duration(hours: 2)))
          : DateTime.now().add(const Duration(hours: 2)),
      location: map['location'] as String? ?? '',
      attendees: List<String>.from(map['attendees'] ?? []),
      maxCapacity: (map['maxCapacity'] ?? map['maxAttendees']) as int? ?? 10,
      category: map['category'] as String? ?? 'General',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] as String? ?? '',
      isPublic: map['isPublic'] as bool? ?? true,
      isOnline: map['isOnline'] as bool? ?? false,
      roomId: map['roomId'] as String?,
      attendeesCount: map['attendeesCount'] as int? ?? 0,
      interestedCount: map['interestedCount'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hostId': hostId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'attendees': attendees,
      'maxCapacity': maxCapacity,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'isPublic': isPublic,
      'isOnline': isOnline,
      'roomId': roomId,
      'attendeesCount': attendeesCount,
      'interestedCount': interestedCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? hostId,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    List<String>? attendees,
    int? maxCapacity,
    String? category,
    double? latitude,
    double? longitude,
    bool? isOnline,
    String? roomId,
    int? attendeesCount,
    int? interestedCount,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hostId: hostId ?? this.hostId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      attendees: attendees ?? this.attendees,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl,
      isPublic: isPublic,
      isOnline: isOnline ?? this.isOnline,
      roomId: roomId ?? this.roomId,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      interestedCount: interestedCount ?? this.interestedCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.hostId == hostId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.location == location &&
        other.attendees == attendees &&
        other.maxCapacity == maxCapacity &&
        other.category == category &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.imageUrl == imageUrl &&
        other.isPublic == isPublic &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        hostId.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        location.hashCode ^
        attendees.hashCode ^
        maxCapacity.hashCode ^
        category.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        imageUrl.hashCode ^
        isPublic.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Event(id: $id, title: $title, hostId: $hostId, startTime: $startTime, location: $location, attendees: ${attendees.length}/$maxCapacity)';
  }
}