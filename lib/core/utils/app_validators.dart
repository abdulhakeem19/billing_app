class AppValidators {
  // ---------------------------------------------------------------------------
  // Generic
  // ---------------------------------------------------------------------------

  /// Returns a validator that rejects null or blank strings.
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  // ---------------------------------------------------------------------------
  // Numeric
  // ---------------------------------------------------------------------------

  /// Validates a price value: non-empty, parseable as a number, and ≥ 0.
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a price';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }

  /// Validates a stock quantity: non-empty, parseable as integer, and ≥ 0.
  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a stock quantity';
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 'Please enter a whole number';
    }
    if (parsed < 0) {
      return 'Stock cannot be negative';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  /// Validates a name: non-empty and within [minLength]–[maxLength] characters.
  static String? Function(String?) name({
    int minLength = 2,
    int maxLength = 100,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter a name';
      }
      final trimmed = value.trim();
      if (trimmed.length < minLength) {
        return 'Name must be at least $minLength characters';
      }
      if (trimmed.length > maxLength) {
        return 'Name must not exceed $maxLength characters';
      }
      return null;
    };
  }

  // ---------------------------------------------------------------------------
  // Contact
  // ---------------------------------------------------------------------------

  /// Validates a phone number: digits only (with optional leading + and spaces),
  /// between 7 and 15 digits in total.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a phone number';
    }
    // Strip optional leading +, spaces, and hyphens before counting digits
    final digits = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final pattern = RegExp(r'^\+?[0-9]{7,15}$');
    if (!pattern.hasMatch(digits)) {
      return 'Please enter a valid phone number (7–15 digits)';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Payment
  // ---------------------------------------------------------------------------

  /// Validates a UPI ID in the format `localpart@handle`.
  /// Returns null if the field is empty (UPI is optional in most flows).
  static String? upiId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // UPI is optional
    }
    final pattern = RegExp(r'^[a-zA-Z0-9._\-+]{2,256}@[a-zA-Z]{2,64}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Invalid UPI ID (e.g. name@bank)';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Product
  // ---------------------------------------------------------------------------

  /// Validates a barcode string: non-empty and at most 48 characters.
  static String? barcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter or scan a barcode';
    }
    if (value.trim().length > 48) {
      return 'Barcode must not exceed 48 characters';
    }
    return null;
  }
}
