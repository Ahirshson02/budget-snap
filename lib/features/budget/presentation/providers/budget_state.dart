import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/budget.dart';

part 'budget_state.freezed.dart';

@freezed
sealed class BudgetState with _$BudgetState {
  const factory BudgetState.initial() = BudgetInitial;
  const factory BudgetState.loading() = BudgetLoading;

  const factory BudgetState.loaded({
    required Budget budget,

    /// Spending totals keyed by category ID.
    /// Only includes expenses that have a categoryId assigned.
    required Map<String, double> spentPerCategory,

    /// Sum of all expenses where categoryId is null.
    /// Tracked separately because uncategorized spending has no
    /// allocated amount — it contributes to total spend but not
    /// to any category's progress bar.
    @Default(0.0) double uncategorizedSpent,
  }) = BudgetLoaded;

  const factory BudgetState.empty({required DateTime month}) = BudgetEmpty;
  const factory BudgetState.error(String message) = BudgetError;
}