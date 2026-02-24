// Conditional re-export: web implementation on web, no-op stub on native platforms.
export 'media_permissions_helper_stub.dart'
    if (dart.library.js_interop) 'media_permissions_helper_web.dart';
