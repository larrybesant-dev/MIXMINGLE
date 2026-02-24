// Stub for non-web platforms: no-op / throws UnsupportedError.
class MultiWindowRoomManager {
  static bool openRoomWindow({
    required String roomId,
    required String roomName,
    required String userId,
    String windowName = '_blank',
  }) {
    // No-op on non-web platforms. Use platform navigator instead.
    return false;
  }

  static void openRoomInCurrentWindow({
    required String roomId,
    required String roomName,
    required String userId,
  }) {
    // No-op on non-web platforms.
  }

  static void closeRoomWindow(String roomId) {}
  static bool isWindowOpen(String roomId) => false;
  static List<String> getOpenRooms() => const [];
  static int getOpenRoomCount() => 0;
  static bool hasOpenWindow(String roomId) => false;
  static void closeAllRooms() {}
}
