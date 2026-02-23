import 'package:freezed_annotation/freezed_annotation.dart';
import 'category.dart';

part 'budget.freezed.dart';

/// Core domain model for a monthly budget.
///
/// A Budget belongs to one user and covers exactly one calendar month.
/// The [month] field is always normalized to the first day of the month
/// (e.g., 2024-03-01) so equality checks are unambiguous.
///
/// [categories] is the full list of spending buckets for this budget.
/// The sum of all [Category.allocatedAmount] values should not exceed
/// [totalBudget], but this is a UI-layer concern, not enforced here.
@freezed
class Budget with _$Budget {
  const Budget._(); // Allows us to add custom getters below

  const factory Budget({
    required String id,
    required String userId,
    required DateTime month,
    required double totalBudget,
    @Default([]) List<Category> categories,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Budget;

  /// Sum of all category allocations.
  double get totalAllocated =>
      categories.fold(0, (sum, c) => sum + c.allocatedAmount);

  /// How much of the total budget has not yet been allocated to a category.
  double get unallocated => totalBudget - totalAllocated;
}