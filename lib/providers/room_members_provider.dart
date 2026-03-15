import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/room_service.dart';
import '../models/room_member_model.dart';

final roomMembersProvider = StreamProvider.family<List<RoomMember>, String>((ref, roomId) {
  return RoomService().streamRoomMembers(roomId);
});
