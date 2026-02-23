import '../models/parsed_receipt.dart';

/// Parses raw OCR text from a receipt into a structured [ParsedReceipt].
///
/// Design philosophy:
/// - Every extraction strategy has at least one fallback.
/// - Prefer returning a partial result over throwing an exception.
/// - All regex patterns are documented so they are maintainable.
/// - The service is a pure function: same input → same output, no side effects.
///
/// Limitations:
/// - Works best on English-language receipts with standard formatting.
/// - Heavily formatted or multi-column receipts may parse poorly.
/// - Handwritten receipts are not supported.
class ReceiptParserService {
  const ReceiptParserService();

  ParsedReceipt parse(String rawText) {
    final lines = _cleanLines(rawText);

    return ParsedReceipt(
      merchant: _extractMerchant(lines),
      date: _extractDate(lines),
      total: _extractTotal(lines),
      items: _extractLineItems(lines),
      rawText: rawText,
    );
  }

  // ----------------------------------------------------------------
  // Line cleaning
  // ----------------------------------------------------------------

  /// Strips empty lines, trims whitespace, and normalizes
  /// multiple spaces to single spaces for consistent parsing.
  List<String> _cleanLines(String text) {
    return text
        .split('\n')
        .map((l) => l.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((l) => l.isNotEmpty)
        .toList();
  }

  // ----------------------------------------------------------------
  // Merchant extraction
  // ----------------------------------------------------------------

  /// The merchant name is almost always in the first 1–4 lines of the
  /// receipt before any date, address, or item data appears.
  /// We skip lines that look like addresses or phone numbers.
  String? _extractMerchant(List<String> lines) {
    // Patterns that indicate a line is NOT the merchant name
    final skipPatterns = [
      RegExp(r'\d{3}[-.\s]\d{3}[-.\s]\d{4}'), // phone number
      RegExp(r'\d+\s+\w+\s+(st|ave|blvd|rd|dr|ln)', caseSensitive: false), // address
      RegExp(r'(thank you|welcome|receipt|invoice)', caseSensitive: false),
      RegExp(r'^\d+$'), // pure numbers
    ];

    for (final line in lines.take(5)) {
      final isSkip = skipPatterns.any((p) => p.hasMatch(line));
      if (!isSkip && line.length >= 3) {
        return _toTitleCase(line);
      }
    }
    return null;
  }

  // ----------------------------------------------------------------
  // Date extraction
  // ----------------------------------------------------------------

  /// Tries multiple date formats commonly found on receipts.
  /// Returns the first match found scanning top-to-bottom.
  DateTime? _extractDate(List<String> lines) {
    final patterns = [
      // MM/DD/YYYY or MM-DD-YYYY
      (
        RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
        _parseMDY,
      ),
      // YYYY/MM/DD or YYYY-MM-DD (ISO-ish)
      (
        RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
        _parseYMD,
      ),
      // DD Month YYYY — e.g. "14 March 2024"
      (
        RegExp(
          r'(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{4})',
          caseSensitive: false,
        ),
        _parseDMonthY,
      ),
      // Month DD, YYYY — e.g. "March 14, 2024"
      (
        RegExp(
          r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{1,2}),?\s+(\d{4})',
          caseSensitive: false,
        ),
        _parseMonthDY,
      ),
    ];

    for (final line in lines) {
      for (final (pattern, parser) in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final result = parser(match);
          if (result != null) return result;
        }
      }
    }
    return null;
  }

  DateTime? _parseMDY(RegExpMatch m) {
    try {
      return DateTime(
        int.parse(m.group(3)!),
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseYMD(RegExpMatch m) {
    try {
      return DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDMonthY(RegExpMatch m) {
    try {
      return DateTime(
        int.parse(m.group(3)!),
        _monthNameToInt(m.group(2)!),
        int.parse(m.group(1)!),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseMonthDY(RegExpMatch m) {
    try {
      return DateTime(
        int.parse(m.group(3)!),
        _monthNameToInt(m.group(1)!),
        int.parse(m.group(2)!),
      );
    } catch (_) {
      return null;
    }
  }

  int _monthNameToInt(String name) {
    const months = {
      'jan': 1, 'feb': 2,  'mar': 3,  'apr': 4,
      'may': 5, 'jun': 6,  'jul': 7,  'aug': 8,
      'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[name.toLowerCase().substring(0, 3)] ?? 1;
  }

  // ----------------------------------------------------------------
  // Total extraction
  // ----------------------------------------------------------------

  /// Scans for lines containing "total" keywords and extracts the
  /// associated dollar amount. Scans bottom-up because the grand
  /// total is typically near the end of the receipt.
  double? _extractTotal(List<String> lines) {
    // Keywords that indicate a total line, ordered by confidence.
    // "grand total" > "total" > "amount due" > "balance due"
    final totalKeywords = RegExp(
      r'(grand\s+total|total\s+due|amount\s+due|balance\s+due|total)',
      caseSensitive: false,
    );
    final pricePattern = RegExp(r'\$?\s*(\d+\.\d{2})');

    // Scan bottom-up — the final total is usually the last matching line
    for (final line in lines.reversed) {
      if (totalKeywords.hasMatch(line)) {
        final priceMatch = pricePattern.firstMatch(line);
        if (priceMatch != null) {
          return double.tryParse(priceMatch.group(1)!);
        }
      }
    }

    // Fallback: find the largest price on the receipt, which is
    // often the total even if not explicitly labeled
    double? largest;
    for (final line in lines) {
      final match = pricePattern.firstMatch(line);
      if (match != null) {
        final value = double.tryParse(match.group(1)!);
        if (value != null && (largest == null || value > largest)) {
          largest = value;
        }
      }
    }
    return largest;
  }

  // ----------------------------------------------------------------
  // Line item extraction
  // ----------------------------------------------------------------

  /// Extracts item name + price pairs.
  ///
  /// Strategy: look for lines that contain both a text description
  /// and a price. Skip lines that look like totals, taxes, or headers.
  List<ParsedLineItem> _extractLineItems(List<String> lines) {
    final items = <ParsedLineItem>[];

    // A line item typically has: some text, optional spaces/dots/dashes,
    // then a price like "4.99" or "$4.99"
    final itemPattern = RegExp(
      r'^(.+?)\s+\$?(\d+\.\d{2})\s*$',
    );

    // Lines containing these keywords are not item lines
    final skipKeywords = RegExp(
      r'(total|subtotal|tax|tip|discount|coupon|savings|change|cash|credit|debit|visa|mastercard|amex|thank|receipt|invoice|date|time|order|table|server|cashier|tel|phone|address)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (skipKeywords.hasMatch(line)) continue;

      final match = itemPattern.firstMatch(line);
      if (match == null) continue;

      final name  = _toTitleCase(match.group(1)!.trim());
      final price = double.tryParse(match.group(2)!);

      if (price == null || price <= 0) continue;
      // Ignore implausibly large single item prices (likely a total)
      if (price > 500) continue;
      // Ignore very short names — probably OCR noise
      if (name.length < 2) continue;

      items.add(ParsedLineItem(name: name, price: price));
    }

    return items;
  }

  // ----------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------

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