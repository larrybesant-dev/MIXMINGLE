// lib/platform/platform_js_util_web.dart
// Web implementation - safe JS conversion fallback

String jsifySafe(Object? value) {
  return value == null ? 'null' : value.toString();
}
