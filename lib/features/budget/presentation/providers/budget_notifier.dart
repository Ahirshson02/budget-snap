import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_exception.dart';
import '../../../../features/receipt/data/providers/expense_repository_provider.dart';
import '../../../../features/receipt/domain/repositories/expense_repository.dart';
import '../../data/providers/budget_repository_provider.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/budget_repository.dart';
import 'budget_state.dart';

/// Notifier for all budget-related state and operations.
///
/// Depends on both [BudgetRepository] and [ExpenseRepository] because
/// the loaded state includes spending totals derived from expenses.
///
/// All public methods follow the same pattern:
///   1. Set loading state
///   2. Call repository
///   3. On success → set loaded state with fresh data
///   4. On failure → set error state with a safe message
///
/// The UI never calls repositories directly — it only calls these methods.
class BudgetNotifier extends StateNotifier<BudgetState> {
  BudgetNotifier({
    required BudgetRepository budgetRepository,
    required ExpenseRepository expenseRepository,
  })  : _budgetRepo = budgetRepository,
        _expenseRepo = expenseRepository,
        super(const BudgetState.initial());

  final BudgetRepository _budgetRepo;
  final ExpenseRepository _expenseRepo;

  // ----------------------------------------------------------------
  // Load
  // ----------------------------------------------------------------

  /// Load the budget for [month] and compute category spending totals.
  /// Call this on screen init and after any mutation.
  Future<void> loadBudget(DateTime month) async {
    state = const BudgetState.loading();

    try {
      final budget = await _budgetRepo.getBudgetByMonth(month);

      if (budget == null) {
        state = BudgetState.empty(month: month);
        return;
      }

      final spent = await _computeSpentPerCategory(budget, month);
      state = BudgetState.loaded(budget: budget, spentPerCategory: spent);
    } on AppException catch (e) {
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  // ----------------------------------------------------------------
  // Budget CRUD
  // ----------------------------------------------------------------

  Future<void> createBudget({
    required DateTime month,
    required double totalBudget,
  }) async {
    state = const BudgetState.loading();

    try {
      final budget = await _budgetRepo.createBudget(
        month: month,
        totalBudget: totalBudget,
      );

      state = BudgetState.loaded(
        budget: budget,
        spentPerCategory: {},
      );
    } on AppException catch (e) {
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  Future<void> updateBudgetTotal(double newTotal) async {
    // Guard: can only update when a budget is currently loaded.
    final current = state;
    if (current is! BudgetLoaded) return;

    // Optimistic update — show the change immediately, roll back on error.
    state = BudgetState.loaded(
      budget: current.budget.copyWith(totalBudget: newTotal),
      spentPerCategory: current.spentPerCategory,
    );

    try {
      final updated = await _budgetRepo.updateBudget(
        budgetId: current.budget.id,
        totalBudget: newTotal,
      );

      state = BudgetState.loaded(
        budget: updated,
        spentPerCategory: current.spentPerCategory,
      );
    } on AppException catch (e) {
      // Roll back to the original state on failure.
      state = current;
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  Future<void> deleteBudget() async {
    final current = state;
    if (current is! BudgetLoaded) return;

    state = const BudgetState.loading();

    try {
      await _budgetRepo.deleteBudget(current.budget.id);
      state = BudgetState.empty(month: current.budget.month);
    } on AppException catch (e) {
      state = current; // Restore on failure
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  // ----------------------------------------------------------------
  // Category CRUD
  // ----------------------------------------------------------------

  Future<void> addCategory({
    required String name,
    required double allocatedAmount,
    String? colorHex,
  }) async {
    final current = state;
    if (current is! BudgetLoaded) return;

    try {
      final category = await _budgetRepo.createCategory(
        budgetId: current.budget.id,
        name: name,
        allocatedAmount: allocatedAmount,
        colorHex: colorHex,
      );

      // Append the new category to the current budget's list.
      final updatedBudget = current.budget.copyWith(
        categories: [...current.budget.categories, category],
      );

      state = BudgetState.loaded(
        budget: updatedBudget,
        spentPerCategory: current.spentPerCategory,
      );
    } on AppException catch (e) {
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required double allocatedAmount,
    String? colorHex,
  }) async {
    final current = state;
    if (current is! BudgetLoaded) return;

    try {
      final updated = await _budgetRepo.updateCategory(
        categoryId: categoryId,
        name: name,
        allocatedAmount: allocatedAmount,
        colorHex: colorHex,
      );

      // Replace the matching category in the list, keep all others.
      final updatedCategories = current.budget.categories
          .map((c) => c.id == categoryId ? updated : c)
          .toList();

      state = BudgetState.loaded(
        budget: current.budget.copyWith(categories: updatedCategories),
        spentPerCategory: current.spentPerCategory,
      );
    } on AppException catch (e) {
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final current = state;
    if (current is! BudgetLoaded) return;

    // Optimistic update: remove locally before server confirms.
    final optimisticCategories = current.budget.categories
        .where((c) => c.id != categoryId)
        .toList();

    state = BudgetState.loaded(
      budget: current.budget.copyWith(categories: optimisticCategories),
      spentPerCategory: {
        ...current.spentPerCategory..remove(categoryId),
      },
    );

    try {
      await _budgetRepo.deleteCategory(categoryId);
    } on AppException catch (e) {
      // Roll back on failure.
      state = current;
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  // ----------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------

  /// Fetches this month's expenses and sums spending per category ID.
  Future<Map<String, double>> _computeSpentPerCategory(
    Budget budget,
    DateTime month,
  ) async {
    final expenses = await _expenseRepo.getExpensesByMonth(month);
    final Map<String, double> totals = {};

    for (final expense in expenses) {
      if (expense.categoryId == null) continue;
      totals[expense.categoryId!] =
          (totals[expense.categoryId!] ?? 0) + expense.total;
    }

    return totals;
  }

  /// Converts a typed [AppException] into a user-friendly string.
  /// Raw exception messages from Supabase are never shown directly.
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

/// Family provider — one notifier instance per month.
///
/// Using .family here means each month gets its own independent state.
/// The home screen for March and the analytics view for February
/// can both be alive simultaneously without interfering.
final budgetNotifierProvider = StateNotifierProvider.family
    .autoDispose<BudgetNotifier, BudgetState, DateTime>(
  (ref, month) {
    return BudgetNotifier(
      budgetRepository: ref.watch(budgetRepositoryProvider),
      expenseRepository: ref.watch(expenseRepositoryProvider),
    );
  },
);