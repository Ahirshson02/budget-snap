import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/expense.dart';

part 'expense_state.freezed.dart';

@freezed
sealed class ExpenseState with _$ExpenseState {
  const factory ExpenseState.initial() = ExpenseInitial;
  const factory ExpenseState.loading() = ExpenseLoading;

  const factory ExpenseState.loaded({
    required List<Expense> expenses,

    /// The month these expenses belong to.
    required DateTime month,

    /// Grand total of all expenses this month.
    required double monthlyTotal,
  }) = ExpenseLoaded;

  const factory ExpenseState.empty({required DateTime month}) = ExpenseEmpty;
  const factory ExpenseState.error(String message) = ExpenseError;
}