// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/core/utils/validators.dart';

void main() {
  group('email', () {
    test('accepts normal addresses', () {
      expect(Validators.email('manager@capeonn.test'), isNull);
      expect(Validators.email('  a.b+c@example.co.in '), isNull);
    });

    test('rejects empty and malformed input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('no-at-sign'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });
  });

  group('newPassword (matches the server policy)', () {
    test('accepts a strong password', () {
      expect(Validators.newPassword('Password@123'), isNull);
      expect(Validators.newPassword('NewPassword1'), isNull);
    });

    test('rejects weak ones', () {
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('Ab1'), isNotNull); // too short
      expect(Validators.newPassword('alllowercase1'), isNotNull); // no upper case
      expect(Validators.newPassword('ALLUPPERCASE1'), isNotNull); // no lower case
      expect(Validators.newPassword('NoDigitsHere'), isNotNull); // no number
    });
  });

  test('matches compares against another field', () {
    final other = TextEditingController(text: 'Secret123');
    final validator = Validators.matches(other);

    expect(validator('Secret123'), isNull);
    expect(validator('Different1'), isNotNull);
  });

  test('notEmpty trims whitespace and names the field', () {
    expect(Validators.notEmpty('  ', 'Reset code'), 'Reset code is required');
    expect(Validators.notEmpty('x'), isNull);
  });
}
