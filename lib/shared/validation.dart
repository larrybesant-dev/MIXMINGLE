/// Shared validation utilities for forms across the app.
/// All validators return null if valid, or an error message string if invalid.
library;

class ValidationHelpers {
  /// Trims leading/trailing whitespace and collapses multiple internal spaces.
  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Validates that a string is not empty after trimming.
  static String? validateNotEmpty(String? value, String fieldName) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates string length within bounds.
  static String? validateLength(
      String? value, int minLength, int maxLength, String fieldName) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Use validateNotEmpty separately if required
    if (v.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (v.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validates required length (non-empty + length bounds).
  static String? validateLengthRequired(
    String? value,
    int minLength,
    int maxLength,
    String fieldName,
  ) {
    final empty = validateNotEmpty(value, fieldName);
    if (empty != null) return empty;
    return validateLength(value, minLength, maxLength, fieldName);
  }

  /// Validates an optional string that, if provided, must meet length bounds.
  static String? validateLengthOptional(
    String? value,
    int minLength,
    int maxLength,
    String fieldName,
  ) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Optional
    if (v.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (v.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validates that a string matches a regex pattern.
  static String? validatePattern(
    String? value,
    RegExp pattern,
    String fieldName,
    String patternDescription,
  ) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Use validateNotEmpty if required
    if (!pattern.hasMatch(v)) {
      return '$fieldName $patternDescription';
    }
    return null;
  }

  /// Validates URL format (basic check).
  static String? validateUrl(String? value, String fieldName) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Optional
    try {
      Uri.parse(v);
      if (!v.startsWith('http://') && !v.startsWith('https://')) {
        return '$fieldName must start with http:// or https://';
      }
      return null;
    } catch (e) {
      return '$fieldName must be a valid URL';
    }
  }

  /// Validates that a string does not contain forbidden characters.
  static String? validateForbiddenChars(
    String? value,
    List<String> forbiddenChars,
    String fieldName,
  ) {
    final v = value ?? '';
    for (final char in forbiddenChars) {
      if (v.contains(char)) {
        return '$fieldName cannot contain "$char"';
      }
    }
    return null;
  }

  /// Validates email format (basic check).
  static String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Optional
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(v)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates that a value is not an email address (for username/displayName).
  static String? validateNotEmail(String? value, String fieldName) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Use validateNotEmpty separately if required
    final emailPattern =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (emailPattern.hasMatch(v)) {
      return '$fieldName cannot be an email address';
    }
    return null;
  }

  /// Validates that a value doesn't contain email-like patterns.
  static String? validateNoEmailPattern(String? value, String fieldName) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    // Check for @domain.extension pattern
    if (v.contains(RegExp(r'@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'))) {
      return '$fieldName cannot contain an email address';
    }
    return null;
  }

  /// Checks if two strings are equal (case-insensitive).
  static bool areEqualIgnoreCase(String? str1, String? str2) {
    if (str1 == null || str2 == null) return false;
    return str1.trim().toLowerCase() == str2.trim().toLowerCase();
  }

  /// Validates that a date is not in the past.
  static String? validateNotPast(DateTime? date, String fieldName) {
    if (date == null) return '$fieldName is required';
    final now = DateTime.now();
    if (date.isBefore(now)) {
      return '$fieldName cannot be in the past';
    }
    return null;
  }

  /// Validates that a number is positive.
  static String? validatePositive(int? value, String fieldName) {
    if (value == null || value <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validates file size in bytes.
  static String? validateFileSize(
      int fileSizeBytes, int maxSizeBytes, String fieldName) {
    if (fileSizeBytes > maxSizeBytes) {
      final maxMB = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$fieldName cannot exceed $maxMB MB';
    }
    return null;
  }

  /// Validates file extension against allowed list.
  static String? validateFileExtension(
      String filename, List<String> allowedExtensions) {
    final ext = filename.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return 'File type .$ext not allowed. Allowed: ${allowedExtensions.join(", ")}';
    }
    return null;
  }
}

// Common validation constants
class ValidationConstants {
  // Display name
  static const int displayNameMinLength = 2;
  static const int displayNameMaxLength = 50;

  // Bio
  static const int bioMaxLength = 160;

  // Event title
  static const int eventTitleMinLength = 3;
  static const int eventTitleMaxLength = 80;

  // Event description
  static const int eventDescriptionMinLength = 10;
  static const int eventDescriptionMaxLength = 500;

  // Chat message
  static const int messageMaxLength = 500;

  // Room name (already set in CreateRoomPage)
  static const int roomNameMinLength = 3;
  static const int roomNameMaxLength = 50;

  // Room description
  static const int roomDescriptionMinLength = 10;
  static const int roomDescriptionMaxLength = 200;

  // File upload
  static const int maxUploadSizeMB = 10; // 10 MB
  static const int maxUploadSizeBytes = maxUploadSizeMB * 1024 * 1024;
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp'
  ];
  static const List<String> allowedDocExtensions = [
    'pdf',
    'doc',
    'docx',
    'txt'
  ];

  // URL validation
  static const String urlPattern = r'^https?://';

  // Forbidden characters
  static const List<String> forbiddenChars = ['<', '>', '"', "'", '&'];
}
