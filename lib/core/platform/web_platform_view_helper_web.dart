// Web implementation: registers an HTML div element as a platform view factory.
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

final Set<String> _registeredViewFactories = <String>{};

/// Dart-side map: element-id → DOM element reference.
/// Exposed to JS via window.__getAgoraVideoElement(id) so Agora can attach
/// video tracks without needing to walk Flutter's shadow DOM.
final Map<String, Object> _elementRefs = {};
bool _lookupRegistered = false;

void _ensureJsLookup() {
  if (_lookupRegistered) return;
  _lookupRegistered = true;
  js_util.setProperty(
    js_util.globalThis,
    '__getAgoraVideoElement',
    js_util.allowInterop((String id) => _elementRefs[id]),
  );
}

void registerVideoViewFactory(String viewId, String elementId) {
  if (_registeredViewFactories.contains(viewId)) {
    return;
  }

  _ensureJsLookup();

  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = elementId;
      div.style.width = '100%';
      div.style.height = '100%';
      div.style.objectFit = 'cover';
      // Store reference so JS can retrieve by ID without shadow DOM traversal.
      _elementRefs[elementId] = div;
      return div;
    },
  );

  _registeredViewFactories.add(viewId);
}
