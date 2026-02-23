import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/app_exception.dart';
import '../../domain/models/parsed_receipt.dart';
import '../../domain/services/ocr_service.dart';
import '../../domain/services/receipt_parser_service.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/providers/expense_repository_provider.dart';
import 'receipt_parse_state.dart';

/// Notifier for the full receipt capture → parse → review → save pipeline.
///
/// Each public method advances the pipeline to the next state.
/// The UI calls these methods in sequence based on user actions.
class ReceiptParseNotifier extends StateNotifier<ReceiptParseState> {
  ReceiptParseNotifier({required ExpenseRepository expenseRepository})
      : _expenseRepo = expenseRepository,
        _imagePicker = ImagePicker(),
        _ocrService   = OcrService(),
        _parserService = const ReceiptParserService(),
        super(const ReceiptParseState.idle());

  final ExpenseRepository _expenseRepo;
  final ImagePicker _imagePicker;
  final OcrService _ocrService;
  final ReceiptParserService _parserService;

  // ----------------------------------------------------------------
  // Step 1: Capture image
  // ----------------------------------------------------------------

  Future<void> captureFromCamera() =>
      _pickImage(ImageSource.camera);

  Future<void> captureFromGallery() =>
      _pickImage(ImageSource.gallery);

  Future<void> _pickImage(ImageSource source) async {
    state = const ReceiptParseState.capturing();

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,   // Balance file size vs OCR quality
        maxWidth: 2048,     // Cap resolution — MLKit works well at this size
      );

      if (picked == null) {
        // User cancelled the picker
        state = const ReceiptParseState.idle();
        return;
      }

      await _runOcr(picked.path);
    } catch (e) {
      state = ReceiptParseState.error(
        'Could not open camera or gallery. Please check app permissions.',
      );
    }
  }

  // ----------------------------------------------------------------
  // Step 2: Run OCR and parse
  // ----------------------------------------------------------------

  Future<void> _runOcr(String imagePath) async {
    state = const ReceiptParseState.parsing();

    try {
      final rawText = await _ocrService.extractText(imagePath);

      if (rawText.trim().isEmpty) {
        state = const ReceiptParseState.error(
          'No text could be detected in this image. '
          'Please try a clearer photo with better lighting.',
        );
        return;
      }

      final parsed = _parserService.parse(rawText);

      state = ReceiptParseState.review(
        parsed: parsed,
        imagePath: imagePath,
      );
    } on OcrException catch (e) {
      state = ReceiptParseState.error(e.message);
    } catch (e) {
      state = ReceiptParseState.error(
        'An error occurred while reading the receipt.',
      );
    }
  }

  // ----------------------------------------------------------------
  // Step 3: Update parsed data during review
  // ----------------------------------------------------------------

  /// Called when the user edits any field in the review form.
  /// Produces a new review state with the updated [ParsedReceipt].
  void updateParsedReceipt(ParsedReceipt updated) {
    final current = state;
    if (current is! ReceiptParseReview) return;

    state = ReceiptParseState.review(
      parsed: updated,
      imagePath: current.imagePath,
    );
  }

  // ----------------------------------------------------------------
  // Step 4: Save expense
  // ----------------------------------------------------------------

  /// Converts the reviewed [ParsedReceipt] into an [Expense] and
  /// persists it. Returns true on success so the UI can navigate away.
  Future<bool> saveExpense({
    required String? categoryId,
    required String? comment,
    required List<({String name, double price, String? categoryId})> items,
  }) async {
    final current = state;
    if (current is! ReceiptParseReview) return false;

    state = const ReceiptParseState.saving();

    try {
      final parsed = current.parsed;

      await _expenseRepo.createExpense(
        date: parsed.date ?? DateTime.now(),
        total: parsed.total ?? 0,
        merchant: parsed.merchant,
        categoryId: categoryId,
        comment: comment,
        items: items,
      );

      state = const ReceiptParseState.idle();
      return true;
    } on AppException catch (e) {
      state = ReceiptParseState.error(
        e is UnauthorizedException
            ? 'Please sign in to save expenses.'
            : 'Failed to save expense. Please try again.',
      );
      return false;
    }
  }

  // ----------------------------------------------------------------
  // Reset
  // ----------------------------------------------------------------

  /// Returns the notifier to idle, discarding any in-progress parse.
  void reset() => state = const ReceiptParseState.idle();

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}

final receiptParseNotifierProvider =
    StateNotifierProvider.autoDispose<ReceiptParseNotifier, ReceiptParseState>(
  (ref) => ReceiptParseNotifier(
    expenseRepository: ref.watch(expenseRepositoryProvider),
  ),
);