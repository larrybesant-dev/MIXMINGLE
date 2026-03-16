import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  final supabase = Supabase.instance.client;

  Future<void> trackOnlineStatus(String userId, bool isOnline) async {
    await supabase.from('presence').upsert({
      'user_id': userId,
      'is_online': isOnline,
      'last_seen': DateTime.now().toIso8601String(),
    });
  }

  Stream<bool> listenToPresence(String userId) async* {
    // Placeholder: implement real-time presence tracking with Supabase Realtime
    yield true;
  }
}
