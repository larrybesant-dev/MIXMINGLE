// ============================================================================
// VALIDATION HELPERS - Central validation logic for all forms
// ============================================================================
//
// Provides validation functions for common fields:
// - Email
// - Password
// - Display name / Username
// - General text fields
//

// All functions return:
// - `null` if input is valid
// - `String` error message if input is invalid
//
// This ensures consistent validation across the app.

class ValidationHelpers {
  // ============================================================================
  // EMAIL VALIDATION
  // ============================================================================

  /// Validate email format
  /// Returns error message if invalid, null if valid
  static String? validateEmail(String? value, {String fieldName = 'Email'}) {
    final v = value?.trim() ?? '';

    // Check if empty
    if (v.isEmpty) {
      return '$fieldName is required';
    }

    // Check basic email pattern
    if (!v.contains('@')) {
      return 'Please enter a valid $fieldName';
    }

    // Check for valid email format: something@domain.extension
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailPattern.hasMatch(v)) {
      return 'Please enter a valid $fieldName address';
    }

    return null; // Valid
  }

  // ============================================================================
  // PASSWORD VALIDATION
  // ============================================================================

  /// Validate password strength
  /// Requires:
  /// - At least 8 characters
  /// - At least 1 uppercase letter
  /// - At least 1 lowercase letter
  /// - At least 1 number
  static String? validatePassword(String? value,
      {String fieldName = 'Password'}) {
    final v = value ?? '';

    // Check if empty
    if (v.isEmpty) {
      return '$fieldName is required';
    }

    // Check minimum length
    if (v.length < 8) {
      return '$fieldName must be at least 8 characters long';
    }

    // Check for uppercase
    if (!v.contains(RegExp(r'[A-Z]'))) {
      return '$fieldName must contain at least one uppercase letter';
    }

    // Check for lowercase
    if (!v.contains(RegExp(r'[a-z]'))) {
      return '$fieldName must contain at least one lowercase letter';
    }

    // Check for number
    if (!v.contains(RegExp(r'[0-9]'))) {
      return '$fieldName must contain at least one number';
    }

    return null; // Valid
  }

  /// Simpler password validation - just checks minimum length
  /// Used for login forms where we don't want to be too strict
  static String? validatePasswordLogin(
    String? value, {
    String fieldName = 'Password',
  }) {
    final v = value ?? '';

    if (v.isEmpty) {
      return '$fieldName is required';
    }

    if (v.length < 6) {
      return '$fieldName must be at least 6 characters';
    }

    return null; // Valid
  }

  // ============================================================================
  // DISPLAY NAME / USERNAME VALIDATION
  // ============================================================================

  /// Validate display name
  /// - Required
  /// - 2-50 characters
  /// - Cannot be an email address
  static String? validateDisplayName(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) {
      return 'Display name is required';
    }

    if (v.length < 2) {
      return 'Display name must be at least 2 characters';
    }

    if (v.length > 50) {
      return 'Display name cannot exceed 50 characters';
    }

    // Check if it's an email address
    if (_isEmailAddress(v)) {
      return 'Display name cannot be an email address';
    }

    // Check for email-like patterns
    if (_hasEmailPattern(v)) {
      return 'Display name cannot contain email patterns (like @domain.com)';
    }

    return null; // Valid
  }

  /// Validate username
  /// - Required
  /// - 3-30 characters
  /// - Only alphanumeric, underscore, hyphen
  /// - Cannot be an email address
  static String? validateUsername(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) {
      return 'Username is required';
    }

    if (v.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (v.length > 30) {
      return 'Username cannot exceed 30 characters';
    }

    // Check for valid characters only: a-z, 0-9, _, -
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }

    // Check if it's an email address
    if (_isEmailAddress(v)) {
      return 'Username cannot be an email address';
    }

    return null; // Valid
  }

  // ============================================================================
  // GENERAL TEXT VALIDATION
  // ============================================================================

  /// Validate required text field
  static String? validateRequired(
    String? value, {
    String fieldName = 'Field',
  }) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) {
      return '$fieldName is required';
    }

    return null; // Valid
  }

  /// Validate optional text field with length constraints
  static String? validateLength(
    String? value, {
    required int minLength,
    required int maxLength,
    String fieldName = 'Value',
  }) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) {
      return null; // Optional field, empty is OK
    }

    if (v.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (v.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }

    return null; // Valid
  }

  /// Validate required text field with length constraints
  static String? validateLengthRequired(
    String? value, {
    required int minLength,
    required int maxLength,
    String fieldName = 'Value',
  }) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) {
      return '$fieldName is required';
    }

    if (v.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (v.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }

    return null; // Valid
  }

  // ============================================================================
  // PASSWORD CONFIRMATION
  // ============================================================================

  /// Validate that two passwords match
  static String? validatePasswordMatch(
    String? password,
    String? confirmation, {
    String fieldName = 'Password',
  }) {
    if ((password ?? '').isEmpty || (confirmation ?? '').isEmpty) {
      return 'Both passwords are required';
    }

    if (password != confirmation) {
      return '$fieldName does not match';
    }

    return null; // Valid
  }

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================

  /// Check if a string is a valid email address
  static bool _isEmailAddress(String value) {
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailPattern.hasMatch(value);
  }

  /// Check if a string contains email-like patterns (@domain.com)
  static bool _hasEmailPattern(String value) {
    final emailPatternInText = RegExp(r'@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    return emailPatternInText.hasMatch(value);
  }

  /// Case-insensitive string comparison
  static bool areEqualIgnoreCase(String? str1, String? str2) {
    if (str1 == null || str2 == null) return false;
    return str1.toLowerCase() == str2.toLowerCase();
  }
}
