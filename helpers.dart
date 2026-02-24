/// helpers.dart
/// Minimal stub so all imports resolve
library;

/// Basic helper functions
class Helpers {
  static String formatDate(DateTime date) => '//';
  static String truncate(String text, int length) => text.length <= length ? text : '${text.substring(0, length)}...';
  static String safeString(String? text) => text ?? '';
  static int safeInt(int? value) => value ?? 0;
  static double safeDouble(double? value) => value ?? 0.0;
  static bool safeBool(bool? value) => value ?? false;
  static dynamic jsInvoke(String method, [dynamic args]) => null;
}
