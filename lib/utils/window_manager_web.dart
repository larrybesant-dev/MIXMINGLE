@JS()
library window_manager_web;

import 'dart:js_interop';

@JS('mixmingleWindows.openRoom')
external void _jsOpenRoom(JSString roomId);

@JS('mixmingleWindows.openPrivateChat')
external void _jsOpenPrivateChat(JSString userId);

@JS('mixmingleWindows.openCam')
external void _jsOpenCam(JSString userId);

@JS('mixmingleWindows.send')
external void _jsSend(JSString event, JSAny? data);

@JS('mixmingleWindows.listen')
external void _jsListen(JSExportedDartFunction callback);

class WindowManager {
  static void openRoom(String roomId) {
    if (roomId.isEmpty) return;
    _jsOpenRoom(roomId.toJS);
  }

  static void openPrivateChat(String userId) {
    if (userId.isEmpty) return;
    _jsOpenPrivateChat(userId.toJS);
  }

  static void openCam(String userId) {
    if (userId.isEmpty) return;
    _jsOpenCam(userId.toJS);
  }

  static void send(String event, Object? data) {
    if (event.isEmpty) return;
    _jsSend(event.toJS, _toJsValue(data));
  }

  static void listen(void Function(Object? message) callback) {
    _jsListen(
      ((JSAny? message) {
        callback(message?.dartify());
      }).toJS,
    );
  }

  static JSAny? _toJsValue(Object? data) {
    if (data == null) return null;
    if (data is String) return data.toJS;
    if (data is bool) return data.toJS;
    if (data is int) return data.toJS;
    if (data is double) return data.toJS;
    try {
      return data.jsify();
    } catch (_) {
      return data.toString().toJS;
    }
  }
}
