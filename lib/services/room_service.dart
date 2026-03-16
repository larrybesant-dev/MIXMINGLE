import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';

class RoomService {
  final supabase = Supabase.instance.client;

  Future<RoomModel?> createRoom(String name, String description, List<String> members) async {
    final response = await supabase.from('rooms').insert({
      'name': name,
      'description': description,
      'members': members,
    }).select().single();
    return RoomModel.fromJson(response);
  }

  Future<void> joinRoom(String roomId, String userId) async {
    await supabase.from('rooms').update({'members': userId}).eq('id', roomId);
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    await supabase.from('rooms').update({'members': null}).eq('id', roomId);
  }

  Future<List<RoomModel>> fetchRooms() async {
    final response = await supabase.from('rooms').select();
    return (response as List).map((r) => RoomModel.fromJson(r)).toList();
  }
}
