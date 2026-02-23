/// App-wide constants that do not belong to theme or config.
abstract class AppConstants {
  /// Maximum number of expenses loaded for analytics queries.
  static const int analyticsExpenseLimit = 200;

  /// Maximum number of line items per receipt.
  static const int maxReceiptLineItems = 50;

  /// Maximum OCR image width passed to MLKit.
  /// Higher values improve accuracy but increase processing time.
  static const double maxOcrImageWidth = 2048;

  /// Image quality passed to image_picker (0–100).
  static const int receiptImageQuality = 90;

  /// Minimum category allocated amount.
  static const double minCategoryAmount = 0.01;

  /// Number of months to look back for analytics.
  static const int analyticsLookbackMonths = 6;
}
