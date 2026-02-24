// lib/platform/platform_js_util_stub.dart
// Non-web stub for js interop utilities used by web-only code.
// This file intentionally throws or returns safe defaults when used on non-web.

String jsifySafe(Object? value) {
  // Non-web environment: return a JSON-like string representation.
  // Tests and non-web runs should not rely on real JS interop.
  return value == null ? 'null' : value.toString();
}
