import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:receipt_recognition/receipt_recognition.dart';

/// Wraps [ReceiptRecognizer] to perform on-device OCR + structured parsing
/// in a single call.
///
/// [ReceiptRecognizer] uses Google MLKit for OCR then runs a layout-aware
/// parser to extract products, prices, totals, store name, and date —
/// returning a fully structured [RecognizedReceipt] instead of raw text.
///
/// [singleScan: true] disables cross-frame stabilization, which is correct
/// for still images from camera or gallery (vs. a live camera feed).
class OcrService {
  OcrService()
      : _recognizer = ReceiptRecognizer(singleScan: true);

  final ReceiptRecognizer _recognizer;

  /// Runs OCR + structured parsing on the image at [imagePath].
  ///
  /// Returns a [RecognizedReceipt] with line items, total, store name,
  /// and purchase date. Throws [OcrException] if processing fails.
  Future<RecognizedReceipt> processReceipt(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      return await _recognizer.processImage(inputImage);
    } catch (e) {
      throw OcrException('Failed to process receipt image: $e');
    }
  }

  /// Releases native resources. Must be called when the service is no longer needed.
  Future<void> dispose() => _recognizer.close();
}

class OcrException implements Exception {
  const OcrException(this.message);
  final String message;

  @override
  String toString() => 'OcrException: $message';
}