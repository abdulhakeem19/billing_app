import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/core/utils/app_validators.dart';

void main() {
  // -------------------------------------------------------------------------
  // required()
  // -------------------------------------------------------------------------
  group('AppValidators.required', () {
    final validator = AppValidators.required('Field is required');

    test('returns error message for null', () {
      expect(validator(null), 'Field is required');
    });

    test('returns error message for empty string', () {
      expect(validator(''), 'Field is required');
    });

    test('returns error message for whitespace-only string', () {
      expect(validator('   '), 'Field is required');
    });

    test('returns null for a non-empty value', () {
      expect(validator('hello'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // price()
  // -------------------------------------------------------------------------
  group('AppValidators.price', () {
    test('returns error for null', () {
      expect(AppValidators.price(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(AppValidators.price(''), isNotNull);
    });

    test('returns error for non-numeric string', () {
      expect(AppValidators.price('abc'), isNotNull);
    });

    test('returns error for negative price', () {
      expect(AppValidators.price('-1'), isNotNull);
    });

    test('returns null for zero', () {
      expect(AppValidators.price('0'), isNull);
    });

    test('returns null for valid positive price', () {
      expect(AppValidators.price('99.99'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // stock()
  // -------------------------------------------------------------------------
  group('AppValidators.stock', () {
    test('returns error for null', () {
      expect(AppValidators.stock(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(AppValidators.stock(''), isNotNull);
    });

    test('returns error for decimal input', () {
      expect(AppValidators.stock('1.5'), isNotNull);
    });

    test('returns error for negative stock', () {
      expect(AppValidators.stock('-1'), isNotNull);
    });

    test('returns null for zero', () {
      expect(AppValidators.stock('0'), isNull);
    });

    test('returns null for valid positive integer', () {
      expect(AppValidators.stock('100'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // name()
  // -------------------------------------------------------------------------
  group('AppValidators.name', () {
    final validator = AppValidators.name();

    test('returns error for null', () {
      expect(validator(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(validator(''), isNotNull);
    });

    test('returns error for single character (below minLength=2)', () {
      expect(validator('A'), isNotNull);
    });

    test('returns null for two characters', () {
      expect(validator('AB'), isNull);
    });

    test('returns null for normal name', () {
      expect(validator('Basmati Rice'), isNull);
    });

    test('returns error when exceeding maxLength', () {
      final longName = 'A' * 101;
      expect(validator(longName), isNotNull);
    });

    test('respects custom maxLength', () {
      final strictValidator = AppValidators.name(maxLength: 5);
      expect(strictValidator('123456'), isNotNull);
      expect(strictValidator('12345'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // phone()
  // -------------------------------------------------------------------------
  group('AppValidators.phone', () {
    test('returns error for null', () {
      expect(AppValidators.phone(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(AppValidators.phone(''), isNotNull);
    });

    test('returns error for too short number (< 7 digits)', () {
      expect(AppValidators.phone('12345'), isNotNull);
    });

    test('returns error for too long number (> 15 digits)', () {
      expect(AppValidators.phone('1234567890123456'), isNotNull);
    });

    test('returns error for alpha characters', () {
      expect(AppValidators.phone('abcdefghij'), isNotNull);
    });

    test('returns null for valid 10-digit number', () {
      expect(AppValidators.phone('9876543210'), isNull);
    });

    test('returns null for number with leading +', () {
      expect(AppValidators.phone('+919876543210'), isNull);
    });

    test('returns null for number with spaces', () {
      expect(AppValidators.phone('+91 98765 43210'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // upiId()
  // -------------------------------------------------------------------------
  group('AppValidators.upiId', () {
    test('returns null for null (UPI is optional)', () {
      expect(AppValidators.upiId(null), isNull);
    });

    test('returns null for empty string (UPI is optional)', () {
      expect(AppValidators.upiId(''), isNull);
    });

    test('returns error for missing @ symbol', () {
      expect(AppValidators.upiId('invalidupiid'), isNotNull);
    });

    test('returns error for space in UPI ID', () {
      expect(AppValidators.upiId('name @bank'), isNotNull);
    });

    test('returns null for valid UPI ID', () {
      expect(AppValidators.upiId('name@okicici'), isNull);
    });

    test('returns null for UPI ID with dots and hyphens', () {
      expect(AppValidators.upiId('first.last-123@okaxis'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // barcode()
  // -------------------------------------------------------------------------
  group('AppValidators.barcode', () {
    test('returns error for null', () {
      expect(AppValidators.barcode(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(AppValidators.barcode(''), isNotNull);
    });

    test('returns error for barcode exceeding 48 characters', () {
      expect(AppValidators.barcode('A' * 49), isNotNull);
    });

    test('returns null for valid barcode', () {
      expect(AppValidators.barcode('8901030867497'), isNull);
    });

    test('returns null for barcode at max length (48 chars)', () {
      expect(AppValidators.barcode('A' * 48), isNull);
    });
  });
}
