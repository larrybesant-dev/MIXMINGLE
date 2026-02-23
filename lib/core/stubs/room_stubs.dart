// lib/core/stubs/room_stubs.dart
// Minimal Room and RoomType stubs to unblock analyzer and test errors.

class Room {
  final String id;
  final RoomType roomType;
  const Room({this.id = 'stub-room', this.roomType = RoomType.voice});

  static Room fromDocument(dynamic doc) => const Room();
  static Room fromMap(dynamic map) => const Room();
  Map<String, dynamic> toMap() => {'id': id, 'roomType': roomType};
}

enum RoomType { voice, video, text }
