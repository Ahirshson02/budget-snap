import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_receipt.freezed.dart';

/// The structured result of running OCR and parsing on a receipt image.
///
/// This is a temporary domain model — it lives only during the review
/// step and is never persisted directly. Once the user confirms, it is
/// converted into an [Expense] and saved via [ExpenseNotifier].
///
/// All fields are nullable because OCR is imperfect. The review form
/// handles null gracefully and prompts the user to fill in missing data.
@freezed
class ParsedReceipt with _$ParsedReceipt {
  const factory ParsedReceipt({
    String? merchant,
    DateTime? date,
    double? total,
    @Default([]) List<ParsedLineItem> items,

    /// The raw OCR text — kept for debugging and for re-parsing
    /// if the user reports a bad parse result.
    required String rawText,
  }) = _ParsedReceipt;
}

/// A single line item extracted from the receipt.
@freezed
class ParsedLineItem with _$ParsedLineItem {
  const factory ParsedLineItem({
    required String name,
    required double price,
  }) = _ParsedLineItem;
}