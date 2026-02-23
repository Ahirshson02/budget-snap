import '../models/budget.dart';
import '../models/category.dart';

/// Contract for all budget and category persistence operations.
///
/// Implementations of this interface handle the actual data source
/// (Supabase, local DB, mock, etc.). The domain and presentation
/// layers only ever depend on this abstract class — never on the
/// concrete implementation.
///
/// All methods return the updated domain model on success so the
/// caller always has fresh state without needing a separate fetch.
abstract class BudgetRepository {
  /// Fetch the budget for a given month.
  /// [month] is normalized to the first of the month internally.
  /// Returns null if no budget exists for that month yet.
  Future<Budget?> getBudgetByMonth(DateTime month);

  /// Fetch all budgets for the current user, sorted newest first.
  Future<List<Budget>> getAllBudgets();

  /// Create a new budget. Throws [ValidationException] if a budget
  /// already exists for that month.
  Future<Budget> createBudget({
    required DateTime month,
    required double totalBudget,
  });

  /// Update the total budget amount for an existing budget.
  Future<Budget> updateBudget({
    required String budgetId,
    required double totalBudget,
  });

  /// Permanently delete a budget and all its categories (cascade).
  Future<void> deleteBudget(String budgetId);

  // --- Category operations ---

  /// Add a new category to an existing budget.
  Future<Category> createCategory({
    required String budgetId,
    required String name,
    required double allocatedAmount,
    String? colorHex,
  });

  /// Update name and/or allocated amount of an existing category.
  Future<Category> updateCategory({
    required String categoryId,
    required String name,
    required double allocatedAmount,
    String? colorHex,
  });

  /// Delete a category. Expenses referencing this category will have
  /// their categoryId set to null (DB ON DELETE SET NULL).
  Future<void> deleteCategory(String categoryId);
}