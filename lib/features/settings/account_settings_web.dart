// Web-specific implementations using dart:js_interop and package:web
import 'dart:js_interop';
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

/// Downloads a JSON file on the web platform
void downloadJsonOnWeb(Uint8List bytes, String filename) {
  final blob = web.Blob([bytes.buffer.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
