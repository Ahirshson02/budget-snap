import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/budget.dart';
import '../../domain/models/category.dart';

part 'budget_state.freezed.dart';

/// All possible states for the budget feature.
///
/// The UI pattern-matches on this sealed class to render the correct
/// widget tree. Using a sealed class instead of a simple loading/error
/// bool prevents the UI from ever showing inconsistent combinations
/// (e.g. showing both a loading spinner and an error at once).
@freezed
sealed class BudgetState with _$BudgetState {
  /// Initial state before any data has been requested.
  const factory BudgetState.initial() = BudgetInitial;

  /// Data is being fetched from Supabase.
  const factory BudgetState.loading() = BudgetLoading;

  /// Budget data is available and ready to display.
  const factory BudgetState.loaded({
    required Budget budget,

    /// Spending totals per category, derived from the current month's
    /// expenses. Computed and cached here so the UI doesn't recalculate
    /// on every rebuild.
    required Map<String, double> spentPerCategory,
  }) = BudgetLoaded;

  /// No budget exists for the requested month.
  const factory BudgetState.empty({
    /// The month that was queried so the UI can offer to create one.
    required DateTime month,
  }) = BudgetEmpty;

  /// An error occurred. [message] is user-safe text (never raw exceptions).
  const factory BudgetState.error(String message) = BudgetError;
}