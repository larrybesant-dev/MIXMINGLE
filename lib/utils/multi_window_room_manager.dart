// Conditional re-export: web implementation on web, no-op stub on native platforms.
export 'multi_window_room_manager_stub.dart'
    if (dart.library.js_interop) 'multi_window_room_manager_web.dart';
