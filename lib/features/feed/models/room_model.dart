// Legacy RoomModel file. No longer used. All logic now in lib/models/room_model.dart
        'isLive': isLive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RoomModel.fromFirestore(DocumentSnapshot doc) =>
    // Legacy RoomModel file. No longer used. All logic now in lib/models/room_model.dart
}
