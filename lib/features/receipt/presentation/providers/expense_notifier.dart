import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_exception.dart';
import '../../data/providers/expense_repository_provider.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import 'expense_state.dart';

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  ExpenseNotifier({required ExpenseRepository expenseRepository})
      : _repo = expenseRepository,
        super(const ExpenseState.initial());

  final ExpenseRepository _repo;

  // ----------------------------------------------------------------
  // Load
  // ----------------------------------------------------------------

  Future<void> loadExpenses(DateTime month) async {
    state = const ExpenseState.loading();

    try {
      final expenses = await _repo.getExpensesByMonth(month);

      if (expenses.isEmpty) {
        state = ExpenseState.empty(month: month);
        return;
      }

      state = ExpenseState.loaded(
        expenses: expenses,
        month: month,
        monthlyTotal: _sumTotal(expenses),
      );
    } on AppException catch (e) {
      state = ExpenseState.error(_friendlyMessage(e));
    }
  }

  // ----------------------------------------------------------------
  // Create
  // ----------------------------------------------------------------

  Future<void> createExpense({
    required DateTime date,
    required double total,
    String? merchant,
    String? categoryId,
    String? comment,
    required List<({String name, double price, String? categoryId})> items,
  }) async {
    // Hold current state so we can restore on error.
    final previous = state;

    // Show a loading state without wiping the existing list.
    // We do this by keeping loaded state and adding a separate
    // isSaving flag would add complexity — simple loading is fine
    // because the save action comes from a modal, not the list screen.
    state = const ExpenseState.loading();

    try {
      final created = await _repo.createExpense(
        date: date,
        total: total,
        merchant: merchant,
        categoryId: categoryId,
        comment: comment,
        items: items,
      );

      // Prepend to the existing list if we had one, otherwise start fresh.
      final currentExpenses = previous is ExpenseLoaded
          ? [created, ...previous.expenses]
          : [created];

      // Extract month from the created expense to keep state consistent.
      final month = previous is ExpenseLoaded
          ? previous.month
          : DateTime(date.year, date.month);

      state = ExpenseState.loaded(
        expenses: currentExpenses,
        month: month,
        monthlyTotal: _sumTotal(currentExpenses),
      );
    } on AppException catch (e) {
      state = previous; // Restore list on failure
      state = ExpenseState.error(_friendlyMessage(e));
    }
  }

  // ----------------------------------------------------------------
  // Update
  // ----------------------------------------------------------------

  Future<void> updateExpense({
    required String expenseId,
    required DateTime date,
    required double total,
    String? merchant,
    String? categoryId,
    String? comment,
  }) async {
    final previous = state;
    if (previous is! ExpenseLoaded) return;

    try {
      final updated = await _repo.updateExpense(
        expenseId: expenseId,
        date: date,
        total: total,
        merchant: merchant,
        categoryId: categoryId,
        comment: comment,
      );

      final updatedList = previous.expenses
          .map((e) => e.id == expenseId ? updated : e)
          .toList();

      state = ExpenseState.loaded(
        expenses: updatedList,
        month: previous.month,
        monthlyTotal: _sumTotal(updatedList),
      );
    } on AppException catch (e) {
      state = ExpenseState.error(_friendlyMessage(e));
    }
  }

  Future<void> updateExpenseItems({
    required String expenseId,
    required List<({String name, double price, String? categoryId})> items,
  }) async {
    final previous = state;
    if (previous is! ExpenseLoaded) return;

    try {
      final updated = await _repo.updateExpenseItems(
        expenseId: expenseId,
        items: items,
      );

      final updatedList = previous.expenses
          .map((e) => e.id == expenseId ? updated : e)
          .toList();

      state = ExpenseState.loaded(
        expenses: updatedList,
        month: previous.month,
        monthlyTotal: _sumTotal(updatedList),
      );
    } on AppException catch (e) {
      state = ExpenseState.error(_friendlyMessage(e));
    }
  }

  // ----------------------------------------------------------------
  // Delete
  // ----------------------------------------------------------------

  Future<void> deleteExpense(String expenseId) async {
    final previous = state;
    if (previous is! ExpenseLoaded) return;

    // Optimistic removal.
    final optimistic = previous.expenses
        .where((e) => e.id != expenseId)
        .toList();

    state = optimistic.isEmpty
        ? ExpenseState.empty(month: previous.month)
        : ExpenseState.loaded(
            expenses: optimistic,
            month: previous.month,
            monthlyTotal: _sumTotal(optimistic),
          );

    try {
      await _repo.deleteExpense(expenseId);
    } on AppException catch (e) {
      state = previous; // Roll back on failure
      state = ExpenseState.error(_friendlyMessage(e));
    }
  }

  // ----------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------

  double _sumTotal(List<Expense> expenses) =>
      expenses.fold(0, (sum, e) => sum + e.total);

  String _friendlyMessage(AppException e) => switch (e) {
        UnauthorizedException() => 'Please sign in to continue.',
        ValidationException()   => e.message,
        NotFoundException()     => 'The requested data could not be found.',
        ServerException()       => 'A server error occurred. Please try again.',
        LocalException()        => 'A local error occurred. Please try again.',
      };
}

// ----------------------------------------------------------------
// Provider
// ----------------------------------------------------------------

final expenseNotifierProvider = StateNotifierProvider.family
    .autoDispose<ExpenseNotifier, ExpenseState, DateTime>(
  (ref, month) {
    return ExpenseNotifier(
      expenseRepository: ref.watch(expenseRepositoryProvider),
    );
  },
);