// Minimal stub for host controls provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HostControls {
  void toggleSlowMode(String roomId, int seconds) {}
  void toggleLockRoom(String roomId) {}
  void muteUser(String roomId, String userId) {}
  void unmuteUser(String roomId, String userId) {}
  void banUser(String roomId, String userId) {}
  void unbanUser(String roomId, String userId) {}
}

final hostControlsProvider = Provider<HostControls>((ref) => HostControls());
