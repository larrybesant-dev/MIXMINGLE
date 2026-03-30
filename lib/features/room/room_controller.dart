import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/models/room_model.dart';

class RoomController extends StateNotifier<RoomModel?> {
  RoomController() : super(null);

  String? _asNullableString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  bool? _asNullableBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return null;
  }

  int? _asNullableInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  void createRoom(RoomModel room) {
    state = room;
  }

  void leaveRoom() {
    state = null;
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    if (state != null && state!.id == roomId) {
      state = state!.copyWith(
        name: _asNullableString(data['name']),
        description: _asNullableString(data['description']),
        isLive: _asNullableBool(data['isLive']),
        isLocked: _asNullableBool(data['isLocked']),
        memberCount: _asNullableInt(data['memberCount']),
      );
    }
  }
}

final roomControllerProvider = StateNotifierProvider<RoomController, RoomModel?>(
  (ref) => RoomController(),
);
