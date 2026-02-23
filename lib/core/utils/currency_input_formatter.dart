import 'package:flutter/services.dart';

/// Restricts a text field to valid currency input.
/// Allows digits and a single decimal point with up to 2 decimal places.
///
/// Usage:
///   inputFormatters: [CurrencyInputFormatter()],
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow empty input
    if (text.isEmpty) return newValue;

    // Allow only digits and one decimal point
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;

    // Allow at most 2 decimal places
    final parts = text.split('.');
    if (parts.length == 2 && parts[1].length > 2) return oldValue;

    return newValue;
  }
}