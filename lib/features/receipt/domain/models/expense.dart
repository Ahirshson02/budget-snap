import 'package:freezed_annotation/freezed_annotation.dart';
import 'expense_item.dart';

part 'expense.freezed.dart';

/// A single expense, typically created from a parsed receipt.
///
/// [categoryId] is nullable because a user might save an expense before
/// assigning it to a category, or the category may be deleted later
/// (the DB uses ON DELETE SET NULL for this foreign key).
///
/// [items] are the individual line items from the receipt. The sum of
/// all item prices may differ from [total] due to tax or tips — we
/// store both and let the user reconcile via the edit form.
@freezed
class Expense with _$Expense {
  const Expense._();

  const factory Expense({
    required String id,
    required String userId,
    String? categoryId,
    String? merchant,
    required DateTime date,
    required double total,
    String? comment,
    @Default([]) List<ExpenseItem> items,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Expense;

  /// Sum of all line item prices.
  double get itemsTotal =>
      items.fold(0, (sum, item) => sum + item.price);

  /// Difference between the receipt total and the sum of line items.
  /// Non-zero when tax, tip, or OCR errors are present.
  double get discrepancy => total - itemsTotal;
}