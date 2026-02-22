// Conditional re-export: full web dashboard on web, simple stub on native platforms.
export 'health_dashboard_stub.dart' if (dart.library.js_interop) 'health_dashboard_web.dart';
