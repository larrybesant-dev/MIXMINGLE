// lib/models/breakout_room_model.dart

class BreakoutRoomModel {
  final String roomId;
  final String name;
  final List<String> participantUids;
  final DateTime createdAt;

  BreakoutRoomModel({
    required this.roomId,
    required this.name,
    required this.participantUids,
    required this.createdAt,
  });

  factory BreakoutRoomModel.fromMap(String roomId, Map<String, dynamic> map) {
    return BreakoutRoomModel(
      roomId: roomId,
      name: map['name'] ?? '',
      participantUids: List<String>.from(map['participantUids'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'participantUids': participantUids,
    'createdAt': createdAt.toIso8601String(),
  };
}
