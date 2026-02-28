import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_exception.dart';
import '../../../receipt/data/providers/expense_repository_provider.dart';
import '../../../receipt/domain/repositories/expense_repository.dart';
import '../../data/providers/budget_repository_provider.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/budget_repository.dart';
import 'budget_state.dart';

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

  Future<void> loadBudget(DateTime month) async {
    state = const BudgetState.loading();

    try {
      final budget = await _budgetRepo.getBudgetByMonth(month);

      if (budget == null) {
        state = BudgetState.empty(month: month);
        return;
      }

      final (spent, uncategorized) =
          await _computeSpentPerCategory(month);

      state = BudgetState.loaded(
        budget: budget,
        spentPerCategory: spent,
        uncategorizedSpent: uncategorized,
      );
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
        uncategorizedSpent: 0,
      );
    } on AppException catch (e) {
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  Future<void> updateBudgetTotal(double newTotal) async {
    final current = state;
    if (current is! BudgetLoaded) return;

    // Optimistic update
    state = BudgetState.loaded(
      budget: current.budget.copyWith(totalBudget: newTotal),
      spentPerCategory: current.spentPerCategory,
      uncategorizedSpent: current.uncategorizedSpent,
    );

    try {
      final updated = await _budgetRepo.updateBudget(
        budgetId: current.budget.id,
        totalBudget: newTotal,
      );

      state = BudgetState.loaded(
        budget: updated,
        spentPerCategory: current.spentPerCategory,
        uncategorizedSpent: current.uncategorizedSpent,
      );
    } on AppException catch (e) {
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
      state = current;
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

      final updatedBudget = current.budget.copyWith(
        categories: [...current.budget.categories, category],
      );

      state = BudgetState.loaded(
        budget: updatedBudget,
        spentPerCategory: current.spentPerCategory,
        uncategorizedSpent: current.uncategorizedSpent,
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

      final updatedCategories = current.budget.categories
          .map((c) => c.id == categoryId ? updated : c)
          .toList();

      state = BudgetState.loaded(
        budget: current.budget.copyWith(categories: updatedCategories),
        spentPerCategory: current.spentPerCategory,
        uncategorizedSpent: current.uncategorizedSpent,
      );
    } on AppException catch (e) {
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final current = state;
    if (current is! BudgetLoaded) return;

    final optimisticCategories = current.budget.categories
        .where((c) => c.id != categoryId)
        .toList();

    final optimisticSpent =
        Map<String, double>.from(current.spentPerCategory)
          ..remove(categoryId);

    state = BudgetState.loaded(
      budget: current.budget.copyWith(categories: optimisticCategories),
      spentPerCategory: optimisticSpent,
      uncategorizedSpent: current.uncategorizedSpent,
    );

    try {
      await _budgetRepo.deleteCategory(categoryId);
    } on AppException catch (e) {
      state = current;
      state = BudgetState.error(_friendlyMessage(e));
    }
  }

  // ----------------------------------------------------------------
  // Private helpers
  // ----------------------------------------------------------------

  /// Returns a tuple of:
  ///   - [Map<String, double>] spent per category ID
  ///   - [double] total uncategorized spending
  ///
  /// Expenses with a null categoryId are not dropped — they are
  /// summed separately so the home screen can show total spend
  /// accurately including uncategorized expenses.
  Future<(Map<String, double>, double)> _computeSpentPerCategory(
    DateTime month,
  ) async {
    final expenses = await _expenseRepo.getExpensesByMonth(month);

    final Map<String, double> totals = {};
    double uncategorized = 0;

    for (final expense in expenses) {
      if (expense.categoryId == null) {
        uncategorized += expense.total;
      } else {
        totals[expense.categoryId!] =
            (totals[expense.categoryId!] ?? 0) + expense.total;
      }
    }

    return (totals, uncategorized);
  }

  String _friendlyMessage(AppException e) => switch (e) {
        UnauthorizedException() => 'Please sign in to continue.',
        ValidationException()   => e.message,
        NotFoundException()     => 'The requested data could not be found.',
        ServerException()       => 'A server error occurred. Please try again.',
        LocalException()        => 'A local error occurred. Please try again.',
      };
}

final budgetNotifierProvider = StateNotifierProvider.family
    .autoDispose<BudgetNotifier, BudgetState, DateTime>(
  (ref, month) {
    return BudgetNotifier(
      budgetRepository: ref.watch(budgetRepositoryProvider),
      expenseRepository: ref.watch(expenseRepositoryProvider),
    );
  },
);