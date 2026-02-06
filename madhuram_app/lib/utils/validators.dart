/// Form validation utilities
class Validators {
  /// Required field validator
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    return null;
  }

  /// Email validator
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Phone number validator
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[+]?[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Minimum length validator
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.length < min) {
      return fieldName != null 
        ? '$fieldName must be at least $min characters' 
        : 'Must be at least $min characters';
    }
    return null;
  }

  /// Maximum length validator
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      return fieldName != null 
        ? '$fieldName must be at most $max characters' 
        : 'Must be at most $max characters';
    }
    return null;
  }

  /// Numeric validator
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Positive number validator
  static String? positiveNumber(String? value, {String? fieldName}) {
    final numericError = numeric(value, fieldName: fieldName);
    if (numericError != null) return numericError;
    
    if (double.parse(value!) <= 0) {
      return 'Must be a positive number';
    }
    return null;
  }

  /// Integer validator
  static String? integer(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a whole number';
    }
    return null;
  }

  /// URL validator
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URLs can be optional
    }
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// GST number validator (Indian)
  static String? gst(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'GST number is required';
    }
    final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (!gstRegex.hasMatch(value.toUpperCase())) {
      return 'Please enter a valid GST number';
    }
    return null;
  }

  /// PAN number validator (Indian)
  static String? pan(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN number is required';
    }
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(value.toUpperCase())) {
      return 'Please enter a valid PAN number';
    }
    return null;
  }

  /// Password validator
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Strong password validator
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    return null;
  }

  /// Confirm password validator
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Date validator (not in past)
  static String? futureDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    if (value.isBefore(DateTime.now())) {
      return 'Date cannot be in the past';
    }
    return null;
  }

  /// Date validator (not in future)
  static String? pastDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    if (value.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }
    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Optional validator wrapper - only validates if value is not empty
  static String? Function(String?) optional(String? Function(String?) validator) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return validator(value);
    };
  }
}
