// Conditional re-export: web implementation on web, stub on native platforms.
export 'web_platform_view_helper_stub.dart'
    if (dart.library.js_interop) 'web_platform_view_helper_web.dart';
