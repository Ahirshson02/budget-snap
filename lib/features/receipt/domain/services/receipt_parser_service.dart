import 'package:receipt_recognition/receipt_recognition.dart';

import '../models/parsed_receipt.dart';

/// Converts a [RecognizedReceipt] from the receipt_recognition package
/// into the app's [ParsedReceipt] domain model.
///
/// All structured data (store, date, total, line items) is already extracted
/// by [ReceiptRecognizer] — this class is a pure mapping layer with no
/// additional regex parsing.
class ReceiptParserService {
  const ReceiptParserService();

  ParsedReceipt parse(RecognizedReceipt receipt) {
    return ParsedReceipt(
      merchant: _merchantName(receipt),
      date: receipt.purchaseDate?.value,
      total: receipt.total?.value,
      items: _lineItems(receipt),
      rawText: '',
    );
  }

  // ----------------------------------------------------------------
  // Private helpers
  // ----------------------------------------------------------------

  /// Store name from the receipt, converted from the package's all-caps
  /// format to title case for display.
  String? _merchantName(RecognizedReceipt receipt) {
    final raw = receipt.store?.value;
    if (raw == null || raw.trim().isEmpty) return null;
    return _toTitleCase(raw.trim());
  }

  /// Maps each [RecognizedPosition] (product + price pair) to a
  /// [ParsedLineItem]. Items with zero/negative prices are skipped.
  List<ParsedLineItem> _lineItems(RecognizedReceipt receipt) {
    return receipt.positions
        .where((pos) => pos.price.value > 0)
        .map((pos) {
          // normalizedText is the package's consensus-stabilized name;
          // fall back to the raw formatted text if it is empty.
          final name = pos.product.normalizedText.trim().isNotEmpty
              ? pos.product.normalizedText.trim()
              : pos.product.text.trim();
          return ParsedLineItem(name: name, price: pos.price.value);
        })
        .where((item) => item.name.isNotEmpty)
        .toList();
  }

  String _toTitleCase(String input) {
    return input
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}