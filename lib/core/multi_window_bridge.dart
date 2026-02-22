// Conditional re-export: web implementation on web, no-op stub on native.
export 'multi_window_bridge_stub.dart'
    if (dart.library.js_interop) 'multi_window_bridge_web.dart';
