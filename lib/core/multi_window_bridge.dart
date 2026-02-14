// ignore_for_file: deprecated_member_use
import 'package:web/web.dart' as web;

class MultiWindowBridge {
  static void openRoom(String roomId) {
    web.window.open('/room/$roomId', '_blank');
  }
}


