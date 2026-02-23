import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wraps google_mlkit_text_recognition to perform on-device OCR.
///
/// Runs entirely on-device — no network call, no API key required.
/// The [TextRecognizer] instance is reused across calls for efficiency
/// and must be closed when the service is disposed.
///
/// This class is intentionally thin — it only does OCR. Parsing the
/// raw text into structured data is the responsibility of
/// [ReceiptParserService], keeping concerns separated and both
/// classes independently testable.
class OcrService {
  OcrService()
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  /// Runs OCR on the image at [imagePath] and returns the extracted text.
  ///
  /// Throws a [OcrException] if recognition fails.
  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognized = await _recognizer.processImage(inputImage);
      return recognized.text;
    } catch (e) {
      throw OcrException('Failed to extract text from image: $e');
    }
  }

  /// Must be called when the service is no longer needed to free
  /// the native MLKit resources.
  Future<void> dispose() => _recognizer.close();
}

class OcrException implements Exception {
  const OcrException(this.message);
  final String message;

  @override
  String toString() => 'OcrException: $message';
}