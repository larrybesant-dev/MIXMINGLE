// Conditional export — each platform resolves to its own implementation.
// Controllers and services import ONLY this file; they never import the
// platform-specific files directly.
export 'agora_platform_service_stub.dart'
    if (dart.library.js_interop) 'agora_platform_service_web.dart'
    if (dart.library.io) 'agora_platform_service_io.dart';
