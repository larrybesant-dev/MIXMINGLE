// lib/core/diagnostics/agora_diagnostics.dart
class AgoraDiagnosticsResult {
  final bool permissionsOk;
  final bool platformSupported;
  final List<String> warnings;
  final List<String> errors;
  final bool isHealthy;

  const AgoraDiagnosticsResult({
    this.permissionsOk = true,
    this.platformSupported = true,
    this.warnings = const [],
    this.errors = const [],
    this.isHealthy = true,
  });
}
