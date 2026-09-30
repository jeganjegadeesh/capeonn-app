import 'package:flutter/widgets.dart';

/// Form validators. The password rule matches the server's policy
/// (8+ characters, upper and lower case, at least one number); the server has the final say.
class Validators {
  Validators._();

  static String? notEmpty(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_email.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[a-z]').hasMatch(value) || !RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Use both upper and lower case letters';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
    return null;
  }

  static FormFieldValidator<String> matches(TextEditingController other, [String message = 'Passwords do not match']) {
    return (value) => value == other.text ? null : message;
  }
}
