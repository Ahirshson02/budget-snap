import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_item.freezed.dart';

/// A single line item from a receipt.
///
/// [categoryId] can differ from its parent [Expense.categoryId] —
/// this enables split-category receipts (e.g., a grocery run where
/// some items are Food and others are Household).
@freezed
class ExpenseItem with _$ExpenseItem {
  const factory ExpenseItem({
    required String id,
    required String expenseId,
    required String userId,
    String? categoryId,
    required String name,
    required double price,
    required DateTime createdAt,
  }) = _ExpenseItem;
}