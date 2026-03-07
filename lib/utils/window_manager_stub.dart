class WindowManager {
  static void openRoom(String roomId) {}

  static void openPrivateChat(String userId) {}

  static void openCam(String userId) {}

  static void send(String event, Object? data) {}

  static void listen(void Function(Object? message) callback) {}
}
