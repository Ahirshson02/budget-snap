import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/parsed_receipt.dart';

part 'receipt_parse_state.freezed.dart';

/// State for the receipt capture → parse → review pipeline.
///
/// The pipeline is strictly linear:
///   idle → capturing → parsing → review → saving → idle
///
/// Each state carries only the data needed for that step.
@freezed
sealed class ReceiptParseState with _$ReceiptParseState {
  /// No receipt is being processed.
  const factory ReceiptParseState.idle() = ReceiptParseIdle;

  /// The image picker is open.
  const factory ReceiptParseState.capturing() = ReceiptParseCapturing;

  /// OCR is running on the selected image.
  const factory ReceiptParseState.parsing() = ReceiptParseParsing;

  /// OCR and parsing succeeded. The user is reviewing and editing results.
  const factory ReceiptParseState.review({
    required ParsedReceipt parsed,
    required String imagePath,
  }) = ReceiptParseReview;

  /// The reviewed expense is being saved to Supabase.
  const factory ReceiptParseState.saving() = ReceiptParseSaving;

  /// An error occurred at any stage of the pipeline.
  const factory ReceiptParseState.error(String message) = ReceiptParseError;
}