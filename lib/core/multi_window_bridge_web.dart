// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

class MultiWindowBridge {
  static void openRoom(String roomId) {
    web.window.open('/room/$roomId', '_blank');
  }
}
