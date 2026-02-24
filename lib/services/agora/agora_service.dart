// lib/services/agora_service.dart
// Conditional export: web platform uses JS interop, IO uses native SDK stub.
export 'agora_service_io.dart'
  if (dart.library.js_interop) 'agora_service_web.dart';
