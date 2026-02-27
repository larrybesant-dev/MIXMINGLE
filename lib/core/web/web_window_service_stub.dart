// lib/core/web/web_window_service_stub.dart
// Non-web stub — all calls are no-ops.

class WebWindowBridge {
  static void open({
    required String url,
    required String name,
    int width = 400,
    int height = 600,
    int left = 100,
    int top = 100,
  }) {
    // No-op on non-web platforms.
  }

  static void closeAll() {}
}
