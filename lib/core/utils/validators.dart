import 'package:flutter/material.dart';

/// Reusable form field validators.
///
/// Each method returns null on success (valid) or a string message
/// on failure (invalid) — the standard Flutter FormField contract.
///
/// Usage:
///   validator: Validators.required('Email is required'),
///   validator: Validators.compose([
///     Validators.required('Amount required'),
///     Validators.positiveAmount(),
///   ]),
abstract class Validators {
  /// Field must not be null or empty after trimming.
  static FormFieldValidator<String> required(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }

  /// Must be a valid email address format.
  static FormFieldValidator<String> email() {
    return (value) {
      if (value == null || value.isEmpty) return null; // let required handle
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
      return null;
    };
  }

  /// Must be a parseable double greater than zero.
  static FormFieldValidator<String> positiveAmount() {
    return (value) {
      if (value == null || value.isEmpty) return null; // let required handle
      final parsed = double.tryParse(value);
      if (parsed == null) return 'Enter a valid number';
      if (parsed <= 0) return 'Amount must be greater than zero';
      return null;
    };
  }

  /// Minimum string length after trimming.
  static FormFieldValidator<String> minLength(int length, String message) {
    return (value) {
      if (value == null || value.trim().length < length) return message;
      return null;
    };
  }

  /// Two fields must match — use for password confirmation.
  static FormFieldValidator<String> mustMatch(
    String Function() getOther,
    String message,
  ) {
    return (value) {
      if (value != getOther()) return message;
      return null;
    };
  }

  /// Runs multiple validators in sequence and returns the first error.
  static FormFieldValidator<String> compose(
    List<FormFieldValidator<String>> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}